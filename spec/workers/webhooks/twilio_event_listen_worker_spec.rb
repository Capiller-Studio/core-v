# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::TwilioEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_short_message, :twilio, account: account) }

  before do
    allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
      { account_id: account.id, channel_id: channel.id }
    )
  end

  describe '#perform' do
    it 'calls Channels::ShortMessage::Twilio::ConversationCreator for incoming Twilio SMS' do
      webhook = create(:webhook_incoming,
        source: 'twilio',
        payload: {
          'Body' => 'Hello via Twilio',
          'From' => '+15559876543'
        }
      )

      expect(Channels::ShortMessage::Twilio::ConversationCreator).to receive(:call).with(
        short_message_channel: channel,
        parsed_params: webhook.payload
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
