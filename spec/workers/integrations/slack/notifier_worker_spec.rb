# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Slack::NotifierWorker, type: :worker do
  let(:webhook_url) { 'https://hooks.slack.com/services/T00/B00/XXXX' }
  let(:payload) { { content: 'Need help with billing', source: 'email' }.to_json }

  describe '#perform' do
    it 'formats message.created event and posts to Slack webhook' do
      expect(HTTParty).to receive(:post).with(
        webhook_url,
        body: kind_of(String),
        headers: { 'Content-Type' => 'application/json' },
        timeout: 5
      ) do |_url, options|
        parsed_body = JSON.parse(options[:body])
        expect(parsed_body).to have_key('blocks')
      end

      described_class.new.perform(webhook_url, 'message.created', payload)
    end

    it 'formats generic events and posts to Slack' do
      expect(HTTParty).to receive(:post).with(
        webhook_url,
        body: { text: 'System Event Triggered: conversation.resolved' }.to_json,
        headers: { 'Content-Type' => 'application/json' },
        timeout: 5
      )

      described_class.new.perform(webhook_url, 'conversation.resolved', {}.to_json)
    end

    it 'rescues errors and logs warning' do
      expect(HTTParty).to receive(:post).and_raise(StandardError.new('Slack API 500'))
      expect(Rails.logger).to receive(:error).with(/Slack Notification Engine Failed: Slack API 500/)

      expect {
        described_class.new.perform(webhook_url, 'message.created', payload)
      }.not_to raise_error
    end
  end
end
