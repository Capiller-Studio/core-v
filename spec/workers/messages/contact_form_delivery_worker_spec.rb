# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::ContactFormDeliveryWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:user) { create(:user) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: user, source: :help_center, status: :sent) }

  describe '#perform' do
    it 'delivers contact form reply via ContactFormMailer and marks message delivered' do
      mail_double = double('MailMessage', deliver_now: true)
      expect(ContactFormMailer).to receive(:reply_message).with(message).and_return(mail_double)

      account.with_shard do
        described_class.new.perform(message.id)
        message.reload
        expect(message.status).to eq('delivered')
      end
    end

    it 'returns early if message is not from help_center source' do
      message.update_column(:source, :email)
      expect(ContactFormMailer).not_to receive(:reply_message)

      account.with_shard do
        described_class.new.perform(message.id)
      end
    end
  end
end
