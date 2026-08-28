# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Webhooks::BroadcasterWorker, type: :worker do
  let(:account) { create(:account) }
  let(:custom_channel) { create(:channel_custom, account: account, hmac_token: 'secret_123') }
  let(:delivery) do
    create(:webhook_delivery,
      resource: custom_channel,
      endpoint_url: 'https://api.example.com/webhook',
      request_payload: { event: 'ticket.created' },
      status: :pending
    )
  end

  describe '#perform' do
    it 'returns if account is not found' do
      expect(HTTParty).not_to receive(:post)
      described_class.new.perform('non-existent-account-id', delivery.id, 1)
    end

    it 'posts payload with signature header and marks delivery successful' do
      expect(HTTParty).to receive(:post).with(
        'https://api.example.com/webhook',
        body: delivery.request_payload.to_json,
        headers: hash_including(
          'Content-Type' => 'application/json',
          'User-Agent' => 'Deskbolic-Webhook-Engine/1.0',
          'Signature' => a_string_matching(/\At=\d+,v1=[a-f0-9]{64}\z/)
        ),
        timeout: 10
      ).and_return(double('Response', success?: true, code: 200, body: 'OK'))

      expect {
        described_class.new.perform(account.id, delivery.id, 1)
      }.to change(Webhook::DeliveryAttempt, :count).by(1)

      delivery.reload
      expect(delivery.status).to eq('successful')
    end

    it 're-enqueues on retryable failure if attempt_number < 3' do
      allow(HTTParty).to receive(:post).and_return(double('Response', success?: false, code: 500, body: 'Error'))
      expect(described_class).to receive(:perform_in).with(10.minutes, account.id, delivery.id, 2)

      described_class.new.perform(account.id, delivery.id, 1)

      delivery.reload
      expect(delivery.status).to eq('pending')
    end

    it 'marks delivery failed if attempt_number >= 3' do
      allow(HTTParty).to receive(:post).and_return(double('Response', success?: false, code: 500, body: 'Error'))
      expect(described_class).not_to receive(:perform_in)

      described_class.new.perform(account.id, delivery.id, 3)

      delivery.reload
      expect(delivery.status).to eq('failed')
    end

    it 'returns early if delivery is already successful' do
      delivery.update_columns(status: :successful)
      expect(HTTParty).not_to receive(:post)

      described_class.new.perform(account.id, delivery.id, 1)
    end
  end
end
