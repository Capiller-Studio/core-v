# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::UnsendHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, primary_inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'wamid_123', source: :whatsapp) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'marks message unsent when message belongs to channel inbox' do
      parsed_params = {
        messages: [{
          protocol_message: {
            type: "revocation",
            message_id: "wamid_123"
          }
        }]
      }

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params).call
      expect(message.reload.deleted?).to be true
    end

    it 'does nothing if message belongs to a different channel inbox' do
      other_inbox = create(:inbox, account: account)
      other_message = create(:message, account: account, inbox: other_inbox, external_id: 'diff_wamid', source: :instagram_direct_message)
      parsed_params = {
        messages: [{
          protocol_message: {
            type: "revocation",
            message_id: "diff_wamid"
          }
        }]
      }

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params).call
      expect(other_message.reload.deleted?).to be false
    end

    it 'does nothing if message_id is blank' do
      blank_params = {
        messages: [{
          protocol_message: {
            type: "revocation",
            message_id: nil
          }
        }]
      }
      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: blank_params).call
      expect(message.reload.deleted?).to be false
    end

    it 'is idempotent when message is already deleted' do
      message.update!(deleted_at: 1.hour.ago)
      parsed_params = {
        messages: [{
          protocol_message: {
            type: "revocation",
            message_id: "wamid_123"
          }
        }]
      }
      expect {
        described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params).call
      }.not_to raise_error
      expect(message.reload.deleted?).to be true
    end
  end
end
