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
    let(:expected_url) { "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/me/messages" }
    
    it 'delivers text message and updates status' do
      expected_params = {
        recipient: { id: 'user123' },
        message: { text: 'Hello IG' }
      }

      mock_response = instance_double(HTTParty::Response, success?: true, body: '{"message_id":"msg_ig_1"}')
      expect(HTTParty).to receive(:post).with(
        expected_url,
        headers: { "Content-Type" => "application/json" },
        query: { access_token: 'ig_token' },
        body: expected_params.to_json
      ).and_return(mock_response)
      
      expect(message).to receive(:update!).with(external_id: 'msg_ig_1', status: :delivered)

      service.call
    end

    context 'when an error occurs' do
      it 'handles JSON response error and calls authorization_error if code 190' do
        mock_response = instance_double(HTTParty::Response, success?: false, body: '{"error":{"code": 190, "message": "Expired token"}}')
        expect(HTTParty).to receive(:post).and_return(mock_response)
        
        expect(message).to receive(:update!).with(status: :failed)
        expect(instagram_channel).to receive(:authorization_error!)
        
        service.call
      end
    end
  end
end
