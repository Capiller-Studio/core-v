require 'rails_helper'

RSpec.describe Conversations::ConversationCreator do
  let(:account) { create(:account) }
  # Using Channel::Custom to avoid Facebook API callback stubs
  let(:channel) { create(:channel_custom, account: account) }
  let!(:inbox) { create(:inbox, account: account, channel: channel, primary_inbox: true) }
  let(:customer) { create(:customer, account: account) }
  let(:sender) { create(:customer, account: account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(Channels::ServicePicker).to receive(:call)
  end

  describe '#call' do
    let(:service) do
      described_class.new(
        channel: channel,
        message: 'Hello world',
        sender: sender,
        customer: customer,
        conversation_source: 'api'
      )
    end

    context 'when no existing conversation exists' do
      it 'creates a new conversation, message, and adds members' do
        expect {
          expect { service.call }.to change(Conversation, :count).by(1)
                                 .and change(Message, :count).by(1)
        }.to change(ConversationMember, :count).by(2)

        conversation = service.conversation
        expect(conversation.account).to eq(account)
        expect(conversation.inbox).to eq(inbox)
        expect(conversation.source).to eq('api')

        message = service.message
        expect(message.conversation).to eq(conversation)
        expect(message.sender).to eq(sender)
        expect(message.content).to eq('Hello world')

        members = conversation.conversation_members.map(&:member)
        expect(members).to include(customer, sender)
      end

      it 'calls Channels::ServicePicker' do
        service.call
        expect(Channels::ServicePicker).to have_received(:call).with(
          conversation: kind_of(Conversation),
          message: kind_of(Message)
        )
      end
    end

    context 'when an existing conversation exists' do
      let!(:existing_conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        # Create a member relationship directly in the DB instead of mocking methods
        create(:conversation_member, conversation: existing_conversation, member: customer, account: account)
      end

      it 'appends message to existing conversation' do
        expect { service.call }.to change(Message, :count).by(1)
                               .and change(Conversation, :count).by(0)

        message = service.message
        expect(message.conversation).to eq(existing_conversation)
        expect(message.content).to eq('Hello world')
      end
    end

    context 'when message creation fails' do
      let(:invalid_service) do
        described_class.new(
          channel: channel,
          message: 'Hello world',
          sender: nil, # Will cause validation failure on Message (sender must exist)
          customer: customer,
          conversation_source: 'api'
        )
      end

      it 'rolls back conversation creation within the transaction' do
        expect {
          begin
            invalid_service.call
          rescue ActiveRecord::RecordInvalid
          end
        }.to change(Conversation, :count).by(0)
         .and change(Message, :count).by(0)
         .and change(ConversationMember, :count).by(0)
      end
    end
  end
end
