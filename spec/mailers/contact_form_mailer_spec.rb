# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactFormMailer, type: :mailer do
  let(:account) { create(:account, name: 'Acme Corp') }
  let(:channel) { create(:channel_contact_form, account: account, send_confirmation_email: true) }
  let(:inbox) { create(:inbox, account: account, channel: channel) }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, title: 'Help with pricing') }
  let(:message) { create(:message, account: account, conversation: conversation, content: 'Thank you for reaching out!') }

  before do
    create(:conversation_member, conversation: conversation, member: customer, account: account)
  end

  describe '#reply_message' do
    it 'delivers reply message to customer email' do
      mail = described_class.reply_message(message)

      expect(mail.to).to eq(['customer@example.com'])
      expect(mail.subject).to include('Help with pricing')
      expect(mail.from).to eq(['support@helpbolic.com'])
      expect(mail[:from].display_names).to eq(["#{message.sender.name} from #{account.name}"])
      expect(mail.reply_to).to eq(["reply+#{conversation.identifier}@#{account.identifier.downcase}.helpbolic.com"])
      expect(mail.message_id).to eq("#{message.id}@helpbolic.com")
      expect(mail.body.encoded).to include('Thank you for reaching out!')
    end

    it 'uses agent name in from display name when sender is a user' do
      agent = create(:user, name: 'Agent Smith', display_name: 'Agent Smith')
      message.update!(sender: agent)
      mail = described_class.reply_message(message)

      expect(mail[:from].display_names).to eq(["Agent Smith from #{account.name}"])
    end

    it 'sets in-reply-to and references headers if conversation data contains email message_id' do
      conversation.update!(data: { 'email' => { 'message_id' => '<original@example.com>', 'references' => ['<ref1@example.com>'] } })
      mail = described_class.reply_message(message)

      expect(mail.in_reply_to).to eq('original@example.com')
      expect(mail.references).to eq(['original@example.com', 'ref1@example.com'])
    end

    it 'returns nil if customer has no email' do
      customer.update_columns(email: nil)
      mail = described_class.reply_message(message)
      expect(mail.to).to be_nil
    end
  end

  describe '#confirmation_email' do
    it 'delivers confirmation email if send_confirmation_email is enabled' do
      mail = described_class.confirmation_email(conversation)

      expect(mail.to).to eq(['customer@example.com'])
      expect(mail.subject).to include('Help with pricing')
      expect(mail.from).to eq(['support@helpbolic.com'])
    end

    it 'does not deliver confirmation email if send_confirmation_email is disabled' do
      channel.update!(send_confirmation_email: false)
      mail = described_class.confirmation_email(conversation)
      expect(mail.to).to be_nil
    end
  end
end
