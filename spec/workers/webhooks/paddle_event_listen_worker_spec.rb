# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::PaddleEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:plan) { create(:plan) }

  describe '#perform' do
    it 'processes transaction.completed event and creates a Transaction' do
      webhook = create(:webhook_incoming,
        source: 'paddle',
        payload: {
          'event_type' => 'transaction.completed',
          'alert_id' => 'alert_123',
          'data' => {
            'id' => 'txn_123',
            'custom_data' => { 'account_id' => account.id },
            'details' => { 'totals' => { 'total' => 2900 } },
            'currency_code' => 'USD'
          }
        }
      )

      expect {
        described_class.new.perform(webhook.id)
      }.to change(Transaction, :count).by(1)

      txn = Transaction.last
      expect(txn.external_id).to eq('txn_123')
      expect(txn.amount).to eq(29.0)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end

    it 'processes subscription.canceled event via Billing::SubscriptionCanceller' do
      subscription = create(:subscription, account: account, plan: plan, provider: :paddle, external_id: 'sub_123')
      webhook = create(:webhook_incoming,
        source: 'paddle',
        payload: {
          'event_type' => 'subscription.canceled',
          'data' => { 'id' => 'sub_123' }
        }
      )

      expect(Billing::SubscriptionCanceller).to receive(:call).with(subscription: subscription, immediate: true)

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
