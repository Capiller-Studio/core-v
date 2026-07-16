require 'rails_helper'

RSpec.describe Channels::Instagram::ConversationCreator do
  let(:channel) { double('Channel::Instagram', primary_inbox: inbox, access_token: 'token', account: account) }
  let(:parsed_message) { double('ParsedMessage', echo?: false, sender_id: 'sender_ig', recipient_id: 'page1') }
  let(:inbox) { double('Inbox') }
  let(:account) { double('Account') }
  let(:service) { described_class.new(channel: channel, parsed_message: parsed_message) }
  
  let(:customer) { double('Customer') }
  let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

  describe '#call' do
    let(:api_mock) { instance_double(Koala::Facebook::API) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::Instagram::MessageCreator', double('MessageCreator'))
      
      allow(Koala::Facebook::API).to receive(:new).with('token').and_return(api_mock)
      allow(api_mock).to receive(:get_object).with('sender_ig').and_return({
        "first_name" => "John",
        "last_name" => "Doe",
        "username" => "john_ig",
        "profile_pic" => "avatar.url"
      })

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
          email: nil
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
        data: {}
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
  end
end
