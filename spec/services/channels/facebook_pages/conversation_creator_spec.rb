require 'rails_helper'

RSpec.describe Channels::FacebookPages::ConversationCreator do
  let(:facebook_page_channel) { double('Channel::FacebookPage', primary_inbox: inbox, access_token: 'token', account: account, page_identifier: 'page1') }
  let(:parsed_message) { double('ParsedMessage', echo?: false, sender_id: 'sender_fb', recipient_id: 'page1') }
  let(:inbox) { double('Inbox') }
  let(:account) { double('Account') }
  let(:service) { described_class.new(facebook_page_channel: facebook_page_channel, parsed_message: parsed_message) }
  
  let(:customer) { double('Customer', locale: 'en') }
  let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

  describe '#call' do
    let(:api_mock) { instance_double(Koala::Facebook::API) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::FacebookPages::MessageCreator', double('MessageCreator'))
      
      allow(Koala::Facebook::API).to receive(:new).with('token').and_return(api_mock)
      allow(api_mock).to receive(:get_object).with('sender_fb').and_return({
        "first_name" => "John",
        "last_name" => "Doe",
        "email" => "john@fb.com",
        "profile_pic" => "avatar.url",
        "locale" => "en_US"
      })

      # Mock concerns
      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)
      allow(account).to receive_message_chain(:identities, :exists?).and_return(false)
      allow(account).to receive_message_chain(:identities, :create!)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::FacebookPages::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(
          external_id: 'sender_fb',
          email: 'john@fb.com',
          params: hash_including(locale: 'en-US')
        )
      ).and_return(customer)

      expect(account.identities).to receive(:create!).with(
        hash_including(
          identity_type: :facebook,
          identifier: 'sender_fb',
          first_name: 'John',
          last_name: 'Doe'
        )
      )

      expect(account.conversations).to receive(:create!).with(
        inbox: inbox,
        source: :facebook_message,
        data: {},
        locale: 'en'
      )

      expect(Channels::FacebookPages::MessageCreator).to receive(:call).with(
        hash_including(
          account: account,
          inbox: inbox,
          conversation: conversation,
          sender: customer,
          facebook_page_channel: facebook_page_channel
        )
      )

      service.call
    end

    it 'proceeds when Koala fails' do
      allow(api_mock).to receive(:get_object).and_raise(Koala::Facebook::AuthenticationError.new(401, 'Auth fail'))
      expect(facebook_page_channel).to receive(:authorization_error!)

      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(external_id: 'sender_fb', email: nil)
      ).and_return(customer)

      service.call
    end

    context 'when message is an echo (sent from account/page)' do
      let(:parsed_message) { double('ParsedMessage', echo?: true, sender_id: 'page1', recipient_id: 'sender_fb') }

      it 'creates the message with sender as account and customer as the recipient' do
        expect(Customers::CustomerCreator).to receive(:call).with(
          hash_including(external_id: 'sender_fb')
        ).and_return(customer)

        expect(Channels::FacebookPages::MessageCreator).to receive(:call).with(
          hash_including(
            account: account,
            inbox: inbox,
            conversation: conversation,
            sender: account,
            facebook_page_channel: facebook_page_channel
          )
        )

        service.call
      end
    end
  end
end
