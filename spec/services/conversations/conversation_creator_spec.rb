require 'rails_helper'

RSpec.describe Conversations::ConversationCreator do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_facebook_page, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: channel, primary_inbox: true) }
  let(:customer) { create(:customer, account: account) }
  let(:sender) { create(:customer, account: account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks).and_return(true)
    allow(channel).to receive(:primary_inbox).and_return(inbox)
    allow(Channels::ServicePicker).to receive(:call)
  end

  describe '#call' do
    let(:service) do
      described_class.new(
        channel: channel,
        message: 'Hello world',
        sender: sender,
        customer: customer,
        conversation_source: 'facebook_message'
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
        expect(conversation.source).to eq('facebook_message')

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
        existing_conversation.conversation_members.create!(member: customer, account: account)
        allow(customer).to receive_message_chain(:conversations, :where, :find_by).and_return(existing_conversation)
      end

      it 'appends message to existing conversation' do
        expect { service.call }.to change(Message, :count).by(1)
                               .and change(Conversation, :count).by(0)

        message = service.message
        expect(message.conversation).to eq(existing_conversation)
      end
    end
  end
end
