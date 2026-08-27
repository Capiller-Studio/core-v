require 'rails_helper'

RSpec.describe Channels::Instagram::ConversationCreator do
  let(:channel) { double('Channel::Instagram', primary_inbox: inbox, access_token: 'token', account: account) }
  let(:parsed_message) { double('ParsedMessage', echo?: false, sender_id: 'sender_ig', recipient_id: 'page1') }
  let(:inbox) { double('Inbox') }
  let(:account) { double('Account') }
  let(:service) { described_class.new(channel: channel, parsed_message: parsed_message) }
  
  let(:customer) { double('Customer', locale: 'en') }
  let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

  describe '#call' do
    let(:mock_response) { instance_double(HTTParty::Response, success?: true, body: { "id" => "sender_ig", "first_name" => "John", "last_name" => "Doe", "username" => "john_ig", "profile_picture_url" => "avatar.url", "locale" => "spanish" }.to_json) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::Instagram::MessageCreator', double('MessageCreator'))
      
      allow(HTTParty).to receive(:get).with(
        "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/sender_ig",
        query: { fields: "id,username,name,profile_picture_url", access_token: "token" }
      ).and_return(mock_response)

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)
      allow(account).to receive_message_chain(:identities, :exists?).and_return(false)
      allow(account).to receive_message_chain(:identities, :create!)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::Instagram::MessageCreator).to receive(:call)
    end

    it 'creates customer, identity, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          external_id: 'sender_ig',
          email: nil,
          params: hash_including(locale: 'es')
        )
      ).and_return(customer)

      expect(account.identities).to receive(:create!).with(
        hash_including(
          identity_type: :instagram,
          identifier: 'sender_ig',
          first_name: 'John',
          last_name: 'Doe'
        )
      )

      expect(account.conversations).to receive(:create!).with(
        inbox: inbox,
        source: :instagram_direct_message,
        data: {},
        locale: 'en'
      )

      expect(Channels::Instagram::MessageCreator).to receive(:call).with(
        hash_including(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: customer,
          instagram_channel: channel
        )
      )

      service.call
    end

    context 'when Instagram returns OAuth authorization error' do
      let(:mock_auth_error_response) do
        instance_double(
          HTTParty::Response,
          success?: false,
          code: 401,
          body: { error: { message: "Error validating access token: Session has expired", code: 190 } }.to_json,
          parsed_response: { "error" => { "message" => "Error validating access token: Session has expired", "code" => 190 } }
        )
      end

      before do
        allow(HTTParty).to receive(:get).and_return(mock_auth_error_response)
      end

      it 'calls authorization_error! on the channel and proceeds with fallback customer attributes' do
        expect(channel).to receive(:authorization_error!)
        expect(Customers::CustomerCreator).to receive(:call).with(
          hash_including(external_id: 'sender_ig')
        ).and_return(customer)

        service.call
      end
    end
  end
end
