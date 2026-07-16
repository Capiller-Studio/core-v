require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::ConversationCreator do
  let(:whatsapp_channel) { double('Channel::Whatsapp', account: account, primary_inbox: inbox, phone_number_id: 'pn123') }
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox') }
  let(:parsed_params) do
    {
      contacts: [{ "wa_id" => "987", "profile" => { "name" => "WA User" } }],
      messages: [{ type: "text", from: "987", id: "msg_wa_1" }]
    }
  end

  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params, account: account) }

  before do
    allow(account).to receive(:with_shard).and_yield
    allow(account).to receive_message_chain(:messages, :find_by).and_return(nil)
    
    stub_const('RedisUtilities::Helpers', double('RedisHelpers'))
    allow(RedisUtilities::Helpers).to receive(:get).and_return(false)
    allow(RedisUtilities::Helpers).to receive(:set)
    allow(RedisUtilities::Helpers).to receive(:delete)

    stub_const('RedisUtilities::MutexHelpers', double('MutexHelpers'))
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#call' do
    let(:customer) { double('Customer') }
    let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::Whatsapp::CloudApi::MessageCreator', double('MessageCreator'))

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)
      allow(account).to receive_message_chain(:identities, :exists?).and_return(false)
      allow(account).to receive_message_chain(:identities, :create!)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::Whatsapp::CloudApi::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(external_id: "987", full_phone_number: "+987")
      )

      expect(account.identities).to receive(:create!).with(
        hash_including(identity_type: :whatsapp, identifier: "987", name: nil)
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(source: :whatsapp)
      )

      expect(Channels::Whatsapp::CloudApi::MessageCreator).to receive(:call).with(
        hash_including(whatsapp_channel: whatsapp_channel, message_type: "text", parsed_message: parsed_params)
      )

      service.call
    end

    context 'with unsupported message type' do
      let(:parsed_params) do
        {
          contacts: [{ "wa_id" => "987", "profile" => { "name" => "WA User" } }],
          messages: [{ type: "reaction", from: "987", id: "msg_wa_1" }]
        }
      end

      it 'does nothing if message type is unsupported' do
        expect(service).not_to receive(:find_inbox)
        service.call
      end
    end
  end
end
