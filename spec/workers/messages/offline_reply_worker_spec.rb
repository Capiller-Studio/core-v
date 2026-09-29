# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::OfflineReplyWorker, type: :worker do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_web_widget, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: web_widget) }
  let(:customer) { create(:customer, account: account, email: 'customer@example.com') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: user, status: :sent) }

  let(:conversation_reply_mailer) do
    Class.new do
      def self.reply(*); end
    end
  end

  before do
    stub_const('ConversationReplyMailer', conversation_reply_mailer)
    create(:conversation_member, conversation: conversation, member: customer)
  end

  describe '#perform' do
    it 'delivers email reply when customer is offline and updates message status to delivered' do
      allow(::Utilities::ActivityHelpers).to receive(:activity?).with(account.id, 'Customer', customer.id).and_return(false)
      mail_double = double('MailMessage', deliver_now: double('Mail', message_id: '<msg-123@example.com>'))
      expect(ConversationReplyMailer).to receive(:reply).with(conversation, message, nil).and_return(mail_double)

      described_class.new.perform(account.id, message.id)

      message.reload
      expect(message.status).to eq('delivered')
      expect(message.external_id).to eq('<msg-123@example.com>')
    end

    it 'skips delivery if customer is actively online' do
      allow(::Utilities::ActivityHelpers).to receive(:activity?).with(account.id, 'Customer', customer.id).and_return(true)
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'skips delivery if message is already read' do
      message.update_column(:status, :read)
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'delivers reply even if conversation was marked as resolved' do
      conversation.update_column(:status, :resolved)
      allow(::Utilities::ActivityHelpers).to receive(:activity?).and_return(false)
      mail_double = double('MailMessage', deliver_now: double('Mail', message_id: '<msg-resolved@example.com>'))
      expect(ConversationReplyMailer).to receive(:reply).with(conversation, message, nil).and_return(mail_double)

      described_class.new.perform(account.id, message.id)
      expect(message.reload.status).to eq('delivered')
    end

    it 'skips delivery if message is deleted' do
      message.update_column(:deleted_at, Time.current)
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'skips delivery if message is personal (private note)' do
      message.update_column(:visibility, 0) # personal
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'skips delivery if message is incoming' do
      message.update_column(:sender_type, 'Customer')
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'skips delivery if message is already delivered with external_id' do
      message.update_columns(status: :delivered, external_id: '<already-sent@example.com>')
      expect(ConversationReplyMailer).not_to receive(:reply)

      described_class.new.perform(account.id, message.id)
    end

    it 'marks status as failed and re-raises on mailer error' do
      allow(::Utilities::ActivityHelpers).to receive(:activity?).and_return(false)
      allow(ConversationReplyMailer).to receive(:reply).and_raise(StandardError.new('SMTP error'))

      expect {
        described_class.new.perform(account.id, message.id)
      }.to raise_error(StandardError, 'SMTP error')

      message.reload
      expect(message.status).to eq('failed')
    end
  end
end
