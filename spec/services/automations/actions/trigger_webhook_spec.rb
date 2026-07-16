require 'rails_helper'

RSpec.describe Automations::Actions::TriggerWebhook do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    stub_const('Automations::WebhookDeliveryWorker', double('WebhookDeliveryWorker', perform_async: true))
  end

  describe '#call' do
    context 'when url is missing' do
      let(:service) { described_class.new(resource: conversation, account: account, params: {}) }

      it 'raises an error' do
        expect { service.call }.to raise_error('url is required')
      end
    end

    context 'when method is invalid' do
      let(:service) { described_class.new(resource: conversation, account: account, params: { url: 'https://example.com', method: 'DELETE' }) }

      it 'raises an error' do
        expect { service.call }.to raise_error('Invalid method: DELETE')
      end
    end

    context 'with valid parameters' do
      let(:url) { 'https://example.com/webhook' }
      let(:headers) { { 'Authorization' => 'Bearer token' } }
      let(:secret) { 'my-secret' }
      let(:service) { described_class.new(resource: conversation, account: account, params: { url: url, headers: headers, secret: secret }) }

      it 'enqueues WebhookDeliveryWorker with correct arguments' do
        freeze_time do
          payload = {
            event: "automation.triggered",
            resource_type: conversation.class.name,
            resource_id: conversation.id,
            account_id: account.id,
            data: conversation.event_payload,
            triggered_at: Time.current.iso8601
          }

          expect(Automations::WebhookDeliveryWorker).to receive(:perform_async).with(
            url,
            "POST",
            headers.to_json,
            payload.to_json,
            secret
          )
          service.call
        end
      end
    end
  end
end
