require 'rails_helper'

RSpec.describe Channels::Instagram::EventListener do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:instagram_channel) { create(:channel_instagram, account: account, primary_inbox: inbox) }
  let(:payload) do
    {
      "entry" => [
        {
          "id" => "entry123",
          "messaging" => [
            {
              "sender" => { "id" => "sender1" },
              "message" => { "mid" => "mid123" }
            }
          ]
        }
      ]
    }
  end

  let(:service) { described_class.new(instagram_channel: instagram_channel, payload: payload) }

  before do
    stub_const('RedisUtilities::MutexHelpers', double('Mutex'))
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#call' do
    it 'processes message events and creates conversation' do
      expect(Channels::Instagram::ConversationCreator).to receive(:call).with(
        channel: instagram_channel,
        parsed_message: an_instance_of(Parser::InstagramMessageParser)
      )

      service.call
    end

    context 'with read event' do
      let(:payload) do
        {
          "entry" => [
            {
              "messaging" => [
                {
                  "sender" => { "id" => "sender1" },
                  "read" => { "watermark" => 12345, "mid" => "mid1" }
                }
              ]
            }
          ]
        }
      end

      it 'enqueues status update worker' do
        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          account.id,
          "read",
          hash_including("watermark" => 12345, "external_ids" => ["mid1"])
        )

        service.call
      end
    end

    context 'with reaction event' do
      let(:customer) { create(:customer, account: account, external_id: 'sender1') }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid123', source: :instagram_direct_message) }

      let(:payload) do
        {
          "entry" => [
            {
              "id" => "entry123",
              "messaging" => [
                {
                  "sender" => { "id" => "sender1" },
                  "reaction" => {
                    "mid" => "mid123",
                    "action" => "react",
                    "emoji" => "❤️",
                    "reaction" => "love"
                  }
                }
              ]
            }
          ]
        }
      end

      it 'processes reaction via Messages::ReactionManager' do
        account.with_shard do
          message
          customer
        end

        expect(Messages::ReactionManager).to receive(:call).with(
          message: message,
          sender: customer,
          emoji: "❤️",
          action: :react,
          reaction_name: "love",
          external_id: "mid123"
        )

        service.call
      end
    end

    context 'with message_edit event' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid123', content: 'Old', source: :instagram_direct_message) }

      let(:payload) do
        {
          "entry" => [
            {
              "id" => "entry123",
              "messaging" => [
                {
                  "sender" => { "id" => "sender1" },
                  "message_edit" => {
                    "mid" => "mid123",
                    "text" => "New edited content"
                  }
                }
              ]
            }
          ]
        }
      end

      it 'updates message content and edit history' do
        account.with_shard do
          message
        end

        service.call
        expect(message.reload.content).to eq("New edited content")
        expect(message.reload.edited?).to be true
      end
    end

    context 'with message_unsend event' do
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }
      let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, external_id: 'mid123', source: :instagram_direct_message) }

      let(:payload) do
        {
          "entry" => [
            {
              "id" => "entry123",
              "messaging" => [
                {
                  "sender" => { "id" => "sender1" },
                  "message_unsend" => {
                    "mid" => "mid123"
                  }
                }
              ]
            }
          ]
        }
      end

      it 'marks message as unsent' do
        account.with_shard do
          message
        end

        service.call
        expect(message.reload.deleted?).to be true
      end
    end
  end
end
