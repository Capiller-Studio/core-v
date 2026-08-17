# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::FacebookEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:facebook_channel) do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    create(:channel_facebook_page, account: account, page_identifier: 'fb_page_123')
  end

  before do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    GlobalRouting.create!(
      route_type: 'facebook_page',
      route_value: 'fb_page_123',
      account: account,
      shard_key: account.shard_key
    )
  end

  describe '#perform' do
    it 'parses incoming message and calls Channels::FacebookPages::ConversationCreator' do
      webhook = create(:webhook_incoming,
        source: 'facebook',
        event_type: 'message',
        payload: {
          'messaging' => {
            'sender' => { 'id' => 'user_123' },
            'recipient' => { 'id' => 'fb_page_123' },
            'message' => { 'mid' => 'mid_123', 'text' => 'Hello FB' }
          }
        }
      )

      expect(Channels::FacebookPages::ConversationCreator).to receive(:call).with(
        facebook_page_channel: facebook_channel,
        parsed_message: kind_of(Parser::FacebookMessageParser)
      )

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
