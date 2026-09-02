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

    it 'handles payment_method.detached event and marks PaymentMethod as removed' do
      pm = create(:payment_method, account: account, external_id: 'pm_detach_123', status: :active)

      webhook = create(:webhook_incoming,
        source: 'stripe',
        payload: {
          'id' => 'evt_detach_123',
          'type' => 'payment_method.detached',
          'data' => {
            'object' => {
              'id' => 'pm_detach_123',
              'customer' => 'cus_123'
            }
          }
        }
      )

      described_class.new.perform(webhook.id)

      pm.reload
      expect(pm.status).to eq('removed')
      expect(webhook.reload.status).to eq('processed')
    end

    it 'handles payment_intent.payment_failed event and marks Transaction as failed' do
      transaction = create(:transaction, account: account, external_id: 'pi_fail_123', status: :pending)

      webhook = create(:webhook_incoming,
        source: 'stripe',
        payload: {
          'id' => 'evt_pi_fail_123',
          'type' => 'payment_intent.payment_failed',
          'data' => {
            'object' => {
              'id' => 'pi_fail_123',
              'customer' => 'cus_123'
            }
          }
        }
      )

      described_class.new.perform(webhook.id)

      transaction.reload
      expect(transaction.status).to eq('failed')
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

    it 'handles charge.dispute.created event via Billing::DisputeHandler' do
      webhook = create(:webhook_incoming,
        source: 'stripe',
        payload: {
          'id' => 'evt_disp_123',
          'type' => 'charge.dispute.created',
          'data' => {
            'object' => {
              'charge' => 'ch_123',
              'payment_intent' => 'pi_123'
            }
          }
        }
      )

      expect(Billing::DisputeHandler).to receive(:call).with(
        transaction_id: 'ch_123',
        payment_intent_id: 'pi_123'
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
