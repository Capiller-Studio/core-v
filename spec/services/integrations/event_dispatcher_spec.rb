require 'rails_helper'

RSpec.describe Integrations::EventDispatcher do
  let(:account) { double('Account') }
  let(:payload) { { "inbox_id" => 5, "data" => "test" } }
  let(:service) { described_class.new(event_name: 'conversation.created', payload: payload, account: account) }

  describe '#call' do
    let(:integrations_scope) { double('IntegrationsScope') }

    before do
      allow(account).to receive(:integrations).and_return(integrations_scope)
    end

    context 'with webhook integration' do
      let(:webhook_integration) do
        double('Integration', 
          provider: 'webhook', 
          subscribed_events: ['conversation.created'],
          subscribed_inboxes: [5],
          webhook_url: 'https://example.com/hook'
        )
      end

      before do
        allow(integrations_scope).to receive(:active).and_return([webhook_integration])
        stub_const('WebhookDelivery', double('WebhookDeliveryClass'))
        stub_const('Integrations::Webhooks::BroadcasterWorker', double('BroadcasterWorker'))
      end

      it 'creates delivery and enqueues broadcaster' do
        delivery = double('WebhookDelivery', id: 10)
        
        expect(WebhookDelivery).to receive(:create!).with(
          integration: webhook_integration,
          event_name: 'conversation.created',
          endpoint_url: 'https://example.com/hook',
          request_payload: payload,
          status: :pending
        ).and_return(delivery)

        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(10, 1)

        service.call
      end

      it 'skips if event is not subscribed' do
        allow(webhook_integration).to receive(:subscribed_events).and_return(['message.created'])
        expect(WebhookDelivery).not_to receive(:create!)
        service.call
      end

      it 'skips if inbox is not subscribed' do
        allow(webhook_integration).to receive(:subscribed_inboxes).and_return([99])
        expect(WebhookDelivery).not_to receive(:create!)
        service.call
      end
    end

    context 'with slack integration' do
      let(:slack_integration) do
        double('Integration', 
          provider: 'slack', 
          webhook_url: 'https://slack.com/hook'
        )
      end

      before do
        allow(integrations_scope).to receive(:active).and_return([slack_integration])
        stub_const('Integrations::Slack::NotifierWorker', double('NotifierWorker'))
      end

      it 'enqueues slack notifier worker' do
        expect(Integrations::Slack::NotifierWorker).to receive(:perform_async).with(
          'https://slack.com/hook',
          'conversation.created',
          payload.to_json
        )

        service.call
      end
    end

    context 'when error occurs' do
      it 'rescues and logs' do
        allow(account).to receive(:integrations).and_raise(StandardError.new("DB Error"))
        expect(Rails.logger).to receive(:error).with(/Integration Dispatcher Failed dynamically: DB Error/)
        
        expect { service.call }.not_to raise_error
      end
    end
  end
end
