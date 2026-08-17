# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::AwsSnsEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_short_message, :aws_sns, account: account) }

  before do
    allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
      { account_id: account.id, channel_id: channel.id }
    )
  end

  describe '#perform' do
    it 'handles SubscriptionConfirmation by fetching SubscribeURL' do
      webhook = create(:webhook_incoming,
        source: 'aws_sns',
        payload: {
          'Type' => 'SubscriptionConfirmation',
          'SubscribeURL' => 'https://sns.amazonaws.com/confirm'
        }
      )

      expect(HTTParty).to receive(:get).with('https://sns.amazonaws.com/confirm')

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end

    it 'handles Notification by calling Channels::ShortMessage::AwsSns::ConversationCreator' do
      webhook = create(:webhook_incoming,
        source: 'aws_sns',
        payload: {
          'Type' => 'Notification',
          'Message' => 'Hello from SMS'
        }
      )

      expect(Channels::ShortMessage::AwsSns::ConversationCreator).to receive(:call).with(
        short_message_channel: channel,
        parsed_params: webhook.payload
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
