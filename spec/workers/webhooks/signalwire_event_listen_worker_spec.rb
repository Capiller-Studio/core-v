# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::SignalwireEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_short_message, :signalwire, account: account) }

  before do
    allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
      { account_id: account.id, channel_id: channel.id }
    )
  end

  describe '#perform' do
    it 'calls Channels::ShortMessage::Signalwire::ConversationCreator for incoming SMS' do
      webhook = create(:webhook_incoming,
        source: 'signalwire',
        payload: {
          'Body' => 'Hello via Signalwire',
          'From' => '+15551234567'
        }
      )

      expect(Channels::ShortMessage::Signalwire::ConversationCreator).to receive(:call).with(
        short_message_channel: channel,
        parsed_params: webhook.payload
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
