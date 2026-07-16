require 'rails_helper'

RSpec.describe Channels::Instagram::MessageSender do
  let(:instagram_channel) { double('Channel::Instagram', instagram_id: 'ig123', access_token: 'ig_token') }
  let(:customer_inbox) { double('CustomerInbox', external_id: 'user123') }
  let(:attachments) { [] }
  let(:message) { double('Message', content: 'Hello IG', attachments: attachments) }
  let(:service) { described_class.new(instagram_channel: instagram_channel, customer_inbox: customer_inbox, message: message) }

  before do
    stub_const('Facebook::Messenger::Bot', double('BotClass'))
  end

  describe '#call' do
    it 'delivers text message and updates status' do
      expected_params = {
        recipient: { id: 'user123' },
        message: { text: 'Hello IG' }
      }

      expect(Facebook::Messenger::Bot).to receive(:deliver).with(expected_params, access_token: 'ig_token').and_return('{"message_id":"msg_ig_1"}')
      expect(message).to receive(:update!).with(external_id: 'msg_ig_1', status: :delivered)

      service.call
    end

    context 'when an error occurs' do
      it 'handles JSON response error and calls authorization_error if code 190' do
        expect(Facebook::Messenger::Bot).to receive(:deliver).and_return('{"error":{"code": 190, "message": "Expired token"}}')
        expect(message).to receive(:update!).with(status: :failed)
        expect(instagram_channel).to receive(:authorization_error!)
        
        service.call
      end
    end
  end
end
