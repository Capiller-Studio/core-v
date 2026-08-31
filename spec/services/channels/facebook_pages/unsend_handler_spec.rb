# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::FacebookPages::UnsendHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:facebook_channel) do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
    create(:channel_facebook_page, account: account, primary_inbox: inbox)
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'fb_mid_123', source: :facebook_message) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    allow_any_instance_of(Channel::FacebookPage).to receive(:subscribe_to_webhooks)
  end

  describe '#call' do
    it 'marks message unsent when message belongs to channel inbox' do
      parsed = double('Parser::FacebookMessageParser', unsend_mid: 'fb_mid_123')
      described_class.new(channel: facebook_channel, parsed_message: parsed).call

      expect(message.reload.deleted?).to be true
    end

    it 'does nothing if message belongs to a different channel inbox' do
      other_inbox = create(:inbox, account: account)
      other_message = create(:message, account: account, inbox: other_inbox, external_id: 'diff_mid', source: :whatsapp)
      parsed = double('Parser::FacebookMessageParser', unsend_mid: 'diff_mid')

      described_class.new(channel: facebook_channel, parsed_message: parsed).call
      expect(other_message.reload.deleted?).to be false
    end

    it 'does nothing if unsend_mid is blank' do
      parsed_blank = double('Parser::FacebookMessageParser', unsend_mid: nil)
      described_class.new(channel: facebook_channel, parsed_message: parsed_blank).call
      expect(message.reload.deleted?).to be false
    end

    it 'is idempotent when message is already deleted' do
      message.update!(deleted_at: 1.hour.ago)
      parsed = double('Parser::FacebookMessageParser', unsend_mid: 'fb_mid_123')
      expect {
        described_class.new(channel: facebook_channel, parsed_message: parsed).call
      }.not_to raise_error
      expect(message.reload.deleted?).to be true
    end
  end
end
