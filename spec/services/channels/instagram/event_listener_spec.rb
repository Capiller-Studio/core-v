require 'rails_helper'

RSpec.describe Channels::Instagram::EventListener do
  let(:instagram_channel) { double('Channel::Instagram', id: 99, account_id: 2) }
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
    stub_const('Parser::InstagramMessageParser', double('ParserClass'))
    stub_const('RedisUtilities::MutexHelpers', double('Mutex'))
    stub_const('Channels::Instagram::ConversationCreator', double('Creator'))
    
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#call' do
    it 'processes message events and creates conversation' do
      parsed = double('ParsedMessage', sender_id: 'sender1')
      expect(Parser::InstagramMessageParser).to receive(:new).with(
        message: { "sender" => { "id" => "sender1" }, "message" => { "mid" => "mid123" } }
      ).and_return(parsed)

      expect(Channels::Instagram::ConversationCreator).to receive(:call).with(
        channel: instagram_channel,
        parsed_message: parsed
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
                  "read" => { "watermark" => 12345 }
                }
              ]
            }
          ]
        }
      end

      before do
        stub_const('Messages::StatusUpdateWorker', double('Worker'))
      end

      it 'enqueues status update worker' do
        parsed = double('ParsedMessage', sender_id: 'sender1', read_watermark: 12345, message: { mids: ['mid1'] })
        allow(Parser::InstagramMessageParser).to receive(:new).and_return(parsed)

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          2,
          :read,
          hash_including("watermark" => 12345)
        )

        service.call
      end
    end
  end
end
