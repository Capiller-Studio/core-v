# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Webhooks::DeliveryRetryWorker, type: :worker do
  let(:account) { create(:account, shard_key: 'de') }
  let(:webhook_integration) do
    create(:integration, account: account, provider: :webhook, status: :active, settings: {
      'webhook_url' => 'https://api.example.com/webhook'
    })
  end
  let(:slack_integration) do
    create(:integration, account: account, provider: :slack, status: :active, settings: {
      'webhook_url' => 'https://hooks.slack.com/services/T00/B00/XXXXX'
    })
  end

  let(:pending_webhook_delivery) do
    create(:webhook_delivery,
      account: account,
      resource: webhook_integration,
      event_name: 'conversation.created',
      endpoint_url: 'https://api.example.com/webhook',
      status: :pending,
      created_at: 2.hours.ago
    )
  end

  let(:pending_slack_delivery) do
    create(:webhook_delivery,
      account: account,
      resource: slack_integration,
      event_name: 'message.created',
      endpoint_url: 'https://hooks.slack.com/services/T00/B00/XXXXX',
      status: :pending,
      created_at: 2.hours.ago
    )
  end

  before do
    Webhook::Delivery.delete_all
    Webhook::DeliveryAttempt.delete_all
  end

  describe '#perform' do
    context 'when called with specific account_id and delivery_id (manual retry)' do
      it 're-enqueues broadcaster worker for webhook integration' do
        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(
          account.id,
          pending_webhook_delivery.id,
          1
        )

        described_class.new.perform(account.id, pending_webhook_delivery.id)
      end

      it 're-enqueues slack notifier worker for slack integration' do
        expect(Integrations::Slack::NotifierWorker).to receive(:perform_async).with(
          account.id,
          pending_slack_delivery.id,
          1
        )

        described_class.new.perform(account.id, pending_slack_delivery.id)
      end

      it 'handles missing account or delivery gracefully' do
        expect(Integrations::Webhooks::BroadcasterWorker).not_to receive(:perform_async)
        described_class.new.perform('invalid-account-id', 'invalid-delivery-id')
      end
    end

    context 'when called without arguments (cron sweep across shards)' do
      before do
        allow_any_instance_of(described_class).to receive(:fetch_active_delivery_ids).and_return(Set.new)
      end

      it 'sweeps orphaned pending deliveries across shards and re-enqueues them' do
        webhook_id = pending_webhook_delivery.id
        slack_id = pending_slack_delivery.id

        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(account.id, webhook_id, 1)
        expect(Integrations::Slack::NotifierWorker).to receive(:perform_async).with(account.id, slack_id, 1)

        described_class.new.perform
      end

      it 'marks delivery failed if max fail safe retries reached (>= 3 attempts)' do
        3.times do |i|
          create(:webhook_delivery_attempt, delivery: pending_webhook_delivery, attempt_number: i + 1)
        end

        expect(Integrations::Webhooks::BroadcasterWorker).not_to receive(:perform_async)

        described_class.new.perform

        expect(pending_webhook_delivery.reload).to be_failed
      end

      it 'skips deliveries that are already active in Sidekiq queues/retries' do
        allow_any_instance_of(described_class).to receive(:fetch_active_delivery_ids).and_return(Set.new([pending_webhook_delivery.id]))

        expect(Integrations::Webhooks::BroadcasterWorker).not_to receive(:perform_async)

        described_class.new.perform
      end

      it 'skips recent pending deliveries (less than 1 hour old)' do
        recent_delivery = create(:webhook_delivery,
          resource: webhook_integration,
          event_name: 'conversation.created',
          status: :pending,
          created_at: 10.minutes.ago
        )

        expect(Integrations::Webhooks::BroadcasterWorker).not_to receive(:perform_async).with(account.id, recent_delivery.id, anything)

        described_class.new.perform
      end
    end
  end
end
