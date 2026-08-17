# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::WebhookDeliveryWorker, type: :worker do
  let(:target_url) { 'https://api.example.com/webhook' }
  let(:custom_headers) { { 'X-Custom-Header' => 'CustomValue' }.to_json }
  let(:payload) { { event: 'ticket.created', id: '123' }.to_json }
  let(:secret) { 'my-secret-key' }

  describe '#perform' do
    it 'delivers webhook with HMAC signature when secret is provided' do
      expect(HTTParty).to receive(:post).with(
        target_url,
        body: payload,
        headers: hash_including(
          'Content-Type' => 'application/json',
          'User-Agent' => 'Deskbolic-Automations/1.0',
          'X-Custom-Header' => 'CustomValue',
          'Deskbolic-Signature' => a_string_matching(/\At=\d+,v1=[a-f0-9]{64}\z/)
        ),
        timeout: 10
      ).and_return(double('Response', success?: true))

      described_class.new.perform(target_url, 'POST', custom_headers, payload, secret)
    end

    it 'delivers GET requests without body' do
      expect(HTTParty).to receive(:get).with(
        target_url,
        headers: hash_including('Content-Type' => 'application/json'),
        timeout: 10
      ).and_return(double('Response', success?: true))

      described_class.new.perform(target_url, 'GET', '{}', payload)
    end

    it 'logs warning when response is not successful' do
      expect(HTTParty).to receive(:post).and_return(double('Response', success?: false, code: 500))
      expect(Rails.logger).to receive(:warn).with(/POST .* returned 500/)

      described_class.new.perform(target_url, 'POST', '{}', payload)
    end

    it 'raises error on network exception to allow Sidekiq retry' do
      expect(HTTParty).to receive(:post).and_raise(StandardError.new('Connection reset'))
      expect(Rails.logger).to receive(:error).with(/Request failed: Connection reset/)

      expect {
        described_class.new.perform(target_url, 'POST', '{}', payload)
      }.to raise_error(StandardError, 'Connection reset')
    end
  end
end
