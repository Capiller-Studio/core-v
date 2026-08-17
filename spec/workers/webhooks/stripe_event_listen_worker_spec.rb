# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::StripeEventListenWorker, type: :worker do
  let!(:account) { create(:account, billing_data: { 'stripe_customer_id' => 'cus_123' }) }

  describe '#perform' do
    it 'handles payment_method.attached event and creates PaymentMethod' do
      webhook = create(:webhook_incoming,
        source: 'stripe',
        payload: {
          'id' => 'evt_123',
          'type' => 'payment_method.attached',
          'data' => {
            'object' => {
              'id' => 'pm_123',
              'customer' => 'cus_123',
              'card' => {
                'last4' => '4242',
                'brand' => 'visa',
                'exp_month' => 12,
                'exp_year' => 2028
              }
            }
          }
        }
      )

      expect {
        described_class.new.perform(webhook.id)
      }.to change(PaymentMethod, :count).by(1)

      pm = PaymentMethod.last
      expect(pm.external_id).to eq('pm_123')
      expect(pm.last_four).to eq('4242')

      webhook.reload
      expect(webhook.status).to eq('processed')
    end

    it 'handles charge.refunded event via Billing::RefundHandler' do
      webhook = create(:webhook_incoming,
        source: 'stripe',
        payload: {
          'id' => 'evt_ref_123',
          'type' => 'charge.refunded',
          'data' => {
            'object' => {
              'id' => 'ch_123',
              'payment_intent' => 'pi_123'
            }
          }
        }
      )

      expect(Billing::RefundHandler).to receive(:call).with(
        transaction_id: 'ch_123',
        payment_intent_id: 'pi_123'
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
