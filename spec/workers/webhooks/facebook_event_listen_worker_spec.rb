# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::FacebookEventListenWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:facebook_channel) do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    create(:channel_facebook_page, account: account, page_identifier: 'fb_page_123', primary_inbox: inbox)
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

    context 'with reaction event' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:customer) { create(:customer, account: account, external_id: 'user_123') }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid_123', source: :facebook_message) }

      it 'processes reaction' do
        account.with_shard do
          facebook_channel
          message
          customer
        end

        webhook = create(:webhook_incoming,
          source: 'facebook',
          event_type: 'reaction',
          payload: {
            'messaging' => {
              'sender' => { 'id' => 'user_123' },
              'recipient' => { 'id' => 'fb_page_123' },
              'reaction' => { 'mid' => 'mid_123', 'action' => 'react', 'emoji' => '❤️' }
            }
          }
        )

        expect(Messages::ReactionManager).to receive(:call).with(
          message: message,
          sender: customer,
          emoji: '❤️',
          action: :react,
          reaction_name: nil,
          external_id: 'mid_123'
        )

        described_class.new.perform(webhook.id)
        expect(webhook.reload.status).to eq('processed')
      end
    end

    context 'with message_edit event' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid_123', content: 'Old', source: :facebook_message) }

      it 'edits message content' do
        account.with_shard do
          facebook_channel
          message
        end

        webhook = create(:webhook_incoming,
          source: 'facebook',
          event_type: 'message_edit',
          payload: {
            'messaging' => {
              'sender' => { 'id' => 'user_123' },
              'recipient' => { 'id' => 'fb_page_123' },
              'message_edit' => { 'mid' => 'mid_123', 'text' => 'New Text' }
            }
          }
        )

        described_class.new.perform(webhook.id)
        expect(webhook.reload.status).to eq('processed')
        expect(message.reload.content).to eq('New Text')
        expect(message.edited?).to be true
      end
    end

    context 'with message_unsend event' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid_123', source: :facebook_message) }

      it 'marks message unsent' do
        account.with_shard do
          facebook_channel
          message
        end

        webhook = create(:webhook_incoming,
          source: 'facebook',
          event_type: 'message_unsend',
          payload: {
            'messaging' => {
              'sender' => { 'id' => 'user_123' },
              'recipient' => { 'id' => 'fb_page_123' },
              'message_unsend' => { 'mid' => 'mid_123' }
            }
          }
        )

        described_class.new.perform(webhook.id)
        expect(webhook.reload.status).to eq('processed')
        expect(message.reload.deleted?).to be true
      end
    end
  end
end
