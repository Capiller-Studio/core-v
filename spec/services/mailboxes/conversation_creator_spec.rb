require 'rails_helper'

RSpec.describe Mailboxes::ConversationCreator do
  let(:account) { create(:account) }

  around do |example|
    Current.set(account: account) { example.run }
  end
  let(:email_channel) { create(:channel_email, account: account) }
  let!(:inbox) { create(:inbox, account: account, channel: email_channel, primary_inbox: true) }
  let(:mail) { double('Mail', message_id: 'msg-123') }
  
  let(:parsed_mail) do
    double('ParsedMail',
      message_id: 'msg-123',
      reply_to_conversation_uuid: nil,
      in_reply_to: nil,
      references: nil,
      subject: 'Support Request',
      from: ['customer@example.com'],
      original_sender: 'customer@example.com',
      receiver: ['support@example.com'],
      sender_name: 'John Doe',
      html_content_parsed: 'Hello',
      text_content_parsed: 'Hello',
      attachments: []
    )
  end

  let!(:global_customer) { create(:customer, account: account, email: 'customer_1@example.com') }

  before do
    allow(Parser::MailParser).to receive(:call).and_return(parsed_mail)
    allow(email_channel).to receive(:primary_inbox).and_return(inbox)
    allow(Customers::CustomerCreator).to receive(:call).and_return(global_customer)
  end

  describe '#call' do
    let(:service) { described_class.new(mail: mail, email_channel: email_channel) }

    context 'when creating a new conversation' do
      it 'creates a new conversation, customer, and message' do
        message = nil
        expect {
          expect {
            message = service.call
          }.to change(Conversation, :count).by(1)
           .and change(Message, :count).by(1)
        }.to change(ConversationMember, :count).by(1)

        conversation = message.conversation
        expect(conversation.account).to eq(account)
        expect(conversation.inbox).to eq(inbox)
        expect(conversation.source).to eq('email')
        expect(conversation.data['email']['subject']).to eq('Support Request')

        message = conversation.messages.last
        expect(message.conversation).to eq(conversation)
        expect(message.sender).to eq(global_customer)
      end
    end

    context 'when finding an existing conversation by uuid' do
      let(:existing_conversation) { create(:conversation, account: account, inbox: inbox) }

      before do
        allow(parsed_mail).to receive(:reply_to_conversation_uuid).and_return(existing_conversation.identifier)
      end

      it 'appends message to existing conversation' do
        message = nil
        expect { message = service.call }.to change(Message, :count).by(1)
         .and change(Conversation, :count).by(0)

        expect(message.conversation).to eq(existing_conversation)
      end
    end

    context 'when finding an existing conversation by in_reply_to' do
      let(:existing_conversation) { create(:conversation, account: account, inbox: inbox) }
      let!(:existing_message) { create(:message, account: account, conversation: existing_conversation, external_id: 'old-123', sender: global_customer) }

      before do
        allow(parsed_mail).to receive(:in_reply_to).and_return('old-123')
      end

      it 'appends message to existing conversation' do
        message = nil
        expect { message = service.call }.to change(Message, :count).by(1)
         .and change(Conversation, :count).by(0)

        expect(message.conversation).to eq(existing_conversation)
      end
    end

    context 'when sender is an existing user' do
      let!(:user) { create(:user, email: 'customer@example.com').tap { |u| create(:account_user, user: u, account: account) } }

      before do
        # Add user to inbox users
        inbox.users << user
      end

      it 'uses the existing user as sender' do
        message = nil
        expect { message = service.call }.to change(Customer, :count).by(0)
        expect(message.sender).to eq(user)
      end
    end

    context 'when sender is an existing customer' do
      let!(:customer) { create(:customer, account: account, email: 'customer@example.com') }

      before do
        allow(inbox).to receive_message_chain(:customers, :find_by).and_return(customer)
      end

      it 'uses the existing customer as sender' do
        message = nil
        expect { message = service.call }.to change(Customer, :count).by(0)
        expect(message.sender).to eq(customer)
      end
    end

    context 'when sender is the email channel address itself' do
      before do
        allow(parsed_mail).to receive(:original_sender).and_return(email_channel.email)
      end

      it 'uses the account as sender and links customer as conversation member' do
        message = service.call
        expect(message.sender).to eq(account)
        expect(message.conversation.conversation_members.map(&:member)).to include(account, global_customer)
        expect(message.conversation.customers).to include(global_customer)
      end
    end
  end
end
