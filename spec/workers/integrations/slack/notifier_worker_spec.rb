# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Slack::NotifierWorker, type: :worker do
  let(:account) { create(:account, locale: 'en') }
  let(:integration) do
    create(:integration, account: account, provider: :slack, status: :active, settings: {
      'webhook_url' => 'https://hooks.slack.com/services/T00/B00/XXXXX',
      'channel' => '#support'
    })
  end

  let(:payload) do
    {
      'content' => 'Hello team, need urgent help!',
      'message_type' => 'incoming',
      'source' => 'whatsapp',
      'sender' => { 'name' => 'John Doe' },
      'conversation' => { 'id' => 'conv_123', 'channel_type' => 'whatsapp' },
      'account' => { 'identifier' => account.identifier }
    }
  end

  let(:delivery) do
    create(:webhook_delivery,
      resource: integration,
      event_name: 'message.created',
      endpoint_url: 'https://hooks.slack.com/services/T00/B00/XXXXX',
      request_payload: payload,
      status: :pending
    )
  end

  describe '#perform' do
    it 'returns if account is not found' do
      expect(HTTParty).not_to receive(:post)
      described_class.new.perform('non-existent-account-id', delivery.id, 1)
    end

    it 'returns if delivery is not found on shard' do
      expect(HTTParty).not_to receive(:post)
      described_class.new.perform(account.id, 'non-existent-id', 1)
    end

    it 'returns early if delivery is already successful' do
      delivery.successful!
      expect(HTTParty).not_to receive(:post)
      described_class.new.perform(account.id, delivery.id, 1)
    end

    it 'skips outgoing message.created event and marks delivery successful' do
      delivery.update!(request_payload: payload.merge('message_type' => 'outgoing'))

      expect(HTTParty).not_to receive(:post)
      described_class.new.perform(account.id, delivery.id, 1)

      expect(delivery.reload).to be_successful
    end

    it 'dispatches formatted block to Slack, creates delivery attempt, and marks delivery successful' do
      response_double = double('HTTPResponse', success?: true, code: 200, body: 'ok')

      expect(HTTParty).to receive(:post) do |url, options|
        expect(url).to eq(delivery.endpoint_url)
        body = JSON.parse(options[:body])
        expect(body['blocks']).to be_present
        expect(body['blocks'].first['text']['text']).to include('New Customer Message')
        expect(options[:body]).to include('Hello team, need urgent help!')
        expect(options[:body]).to include('John Doe')
        response_double
      end

      expect {
        described_class.new.perform(account.id, delivery.id, 1)
      }.to change(Webhook::DeliveryAttempt, :count).by(1)

      attempt = delivery.attempts.last
      expect(attempt.attempt_number).to eq(1)
      expect(attempt.http_status).to eq(200)
      expect(attempt.response_body).to eq('ok')
      expect(attempt.error_trace).to be_nil

      expect(delivery.reload).to be_successful
    end

    it 'retries and records failure attempt when HTTP request fails on attempt 1' do
      response_double = double('HTTPResponse', success?: false, code: 500, body: 'Internal Server Error')
      allow(HTTParty).to receive(:post).and_return(response_double)

      expect(described_class).to receive(:perform_in).with(5.minutes, account.id, delivery.id, 2)

      expect {
        described_class.new.perform(account.id, delivery.id, 1)
      }.to change(Webhook::DeliveryAttempt, :count).by(1)

      attempt = delivery.attempts.last
      expect(attempt.attempt_number).to eq(1)
      expect(attempt.http_status).to eq(500)
      expect(attempt.error_trace).to include('Completed with HTTP 500')

      expect(delivery.reload).to be_pending
    end

    it 'marks delivery failed when attempt 3 fails' do
      response_double = double('HTTPResponse', success?: false, code: 500, body: 'Internal Server Error')
      allow(HTTParty).to receive(:post).and_return(response_double)

      expect(described_class).not_to receive(:perform_in)

      described_class.new.perform(account.id, delivery.id, 3)

      expect(delivery.reload).to be_failed
    end

    it 'handles network exceptions gracefully and records error trace' do
      allow(HTTParty).to receive(:post).and_raise(StandardError.new('Connection timeout'))

      expect(described_class).to receive(:perform_in).with(5.minutes, account.id, delivery.id, 2)

      expect {
        described_class.new.perform(account.id, delivery.id, 1)
      }.to change(Webhook::DeliveryAttempt, :count).by(1)

      attempt = delivery.attempts.last
      expect(attempt.error_trace).to eq('Connection timeout')
    end

    it 'localizes slack message according to account locale' do
      account.update!(locale: 'fr')
      response_double = double('HTTPResponse', success?: true, code: 200, body: 'ok')

      expect(HTTParty).to receive(:post) do |_url, options|
        body = JSON.parse(options[:body])
        expect(body['blocks'].first['text']['text']).to include('Nouveau message client')
        response_double
      end

      described_class.new.perform(account.id, delivery.id, 1)
    end
  end
end
