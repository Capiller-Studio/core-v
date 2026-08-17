# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::CustomEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_custom, account: account, status: :active) }

  before do
    allow_any_instance_of(Webhook::Incoming).to receive(:route_params).and_return(
      { account_id: account.id, channel_id: channel.id }
    )
  end

  describe '#perform' do
    it 'creates a message using Channels::Custom::ConversationCreator on message.created event' do
      webhook = create(:webhook_incoming,
        source: 'custom',
        payload: {
          event: 'message.created',
          message: { content: 'Hello custom channel' },
          customer: { email: 'custom@example.com', name: 'Custom User' }
        }
      )

      creator_double = double('Channels::Custom::ConversationCreator', call: true)
      expect(Channels::Custom::ConversationCreator).to receive(:new).with(
        hash_including(
          custom_channel: channel,
          content: 'Hello custom channel'
        )
      ).and_return(creator_double)

      described_class.new.perform(webhook.id)

      webhook.reload
      expect(webhook.status).to eq('processed')
    end
  end
end
