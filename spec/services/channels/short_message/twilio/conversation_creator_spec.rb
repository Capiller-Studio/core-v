require 'rails_helper'

RSpec.describe Channels::ShortMessage::Twilio::ConversationCreator do
  let(:channel) { double('Channel::ShortMessage', account: account, primary_inbox: inbox, phone_number: '+199999', full_phone_number: '+199999') }
  let(:account) { double('Account', id: 1) }
  let(:inbox) { double('Inbox') }
  let(:parsed_params) do
    { "From" => "+12345", "MessageSid" => "SM123" }
  end

  let(:service) { described_class.new(short_message_channel: channel, parsed_params: parsed_params, account: account) }

  before do
    stub_const('RedisUtilities::Helpers', double('RedisHelpers'))
    allow(RedisUtilities::Helpers).to receive(:get).and_return(nil)
    allow(RedisUtilities::Helpers).to receive(:set)
    allow(RedisUtilities::Helpers).to receive(:delete)
    
    allow(account).to receive_message_chain(:messages, :exists?).and_return(false)
  end

  describe '#call' do
    let(:customer) { double('Customer') }
    let(:conversation) { double('Conversation', conversation_members: double(find_or_create_by!: true)) }

    before do
      stub_const('Customers::CustomerCreator', double('CustomerCreator'))
      stub_const('Channels::ShortMessage::Twilio::MessageCreator', double('MessageCreator'))

      allow(service).to receive(:find_or_reopen_conversation).and_return(nil)
      allow(account).to receive_message_chain(:conversations, :create!).and_return(conversation)

      allow(Customers::CustomerCreator).to receive(:call).and_return(customer)
      allow(Channels::ShortMessage::Twilio::MessageCreator).to receive(:call)
    end

    it 'creates customer, conversation, and message' do
      expect(Customers::CustomerCreator).to receive(:call).with(
        hash_including(external_id: "+12345", full_phone_number: "+12345")
      )

      expect(account.conversations).to receive(:create!).with(
        hash_including(source: :sms)
      )

      expect(Channels::ShortMessage::Twilio::MessageCreator).to receive(:call).with(
        hash_including(short_message_channel: channel, parsed_message: parsed_params, sender: customer)
      )

      service.call
    end

    context 'when SMS is an echo (sent from channel phone number)' do
      let(:parsed_params) do
        { "From" => "+199999", "To" => "+12345", "MessageSid" => "SM_echo" }
      end

      it 'creates customer for recipient and message with sender as account' do
        expect(Customers::CustomerCreator).to receive(:call).with(
          hash_including(external_id: "+12345", full_phone_number: "+12345")
        ).and_return(customer)

        expect(Channels::ShortMessage::Twilio::MessageCreator).to receive(:call).with(
          hash_including(
            account: account,
            inbox: inbox,
            conversation: conversation,
            sender: account,
            short_message_channel: channel
          )
        )

        service.call
      end
    end
  end
end
