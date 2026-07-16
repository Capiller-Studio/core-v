require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::EventListener do
  let(:whatsapp_channel) { double('Channel::Whatsapp', id: 5, account: account, account_id: 1) }
  let(:account) { double('Account', id: 1) }
  
  before do
    allow(account).to receive(:with_shard).and_yield
  end

  describe '#call' do
    context 'when parsing statuses' do
      let(:params) do
        {
          entry: [
            {
              "changes" => [
                {
                  "value" => {
                    statuses: [
                      { id: "wa_msg_1", status: "read" }
                    ]
                  }
                }
              ]
            }
          ]
        }
      end

      let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, params: params, account: account) }

      it 'enqueues status update worker' do
        stub_const('Messages::StatusUpdateWorker', double('Worker'))
        
        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          1,
          "read",
          hash_including("external_ids" => ["wa_msg_1"])
        )

        service.call
      end
    end

    context 'when parsing messages' do
      let(:params) do
        {
          entry: [
            {
              "changes" => [
                {
                  "value" => {
                    messages: [
                      { id: "wa_msg_2" }
                    ]
                  }
                }
              ]
            }
          ]
        }
      end

      let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, params: params, account: account) }

      it 'calls ConversationCreator' do
        stub_const('Channels::Whatsapp::CloudApi::ConversationCreator', double('Creator'))
        
        expect(Channels::Whatsapp::CloudApi::ConversationCreator).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: { messages: [{ id: "wa_msg_2" }] },
          account: account
        )

        service.call
      end
    end
  end
end
