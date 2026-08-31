# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::EditHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, primary_inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'wamid_123', content: 'Original', source: :whatsapp) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'updates message content and edited_at when message belongs to channel inbox' do
      parsed_params = {
        messages: [{
          protocol_message: {
            type: "edited_message",
            message_id: "wamid_123",
            edited_message: { text: { body: "Edited WA text" } }
          }
        }]
      }

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params).call
      expect(message.reload.content).to eq("Edited WA text")
      expect(message.edited?).to be true
    end

    it 'does nothing if message belongs to a different channel inbox' do
      other_inbox = create(:inbox, account: account)
      other_message = create(:message, account: account, inbox: other_inbox, external_id: 'diff_wamid', content: 'Unchanged', source: :instagram_direct_message)
      parsed_params = {
        messages: [{
          protocol_message: {
            type: "edited_message",
            message_id: "diff_wamid",
            edited_message: { text: { body: "Should not apply" } }
          }
        }]
      }

      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params).call
      expect(other_message.reload.content).to eq('Unchanged')
      expect(other_message.reload.edited?).to be false
    end

    it 'does nothing if message_id or body is blank' do
      blank_text_params = {
        messages: [{
          protocol_message: {
            type: "edited_message",
            message_id: "wamid_123",
            edited_message: { text: { body: "" } }
          }
        }]
      }
      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: blank_text_params).call
      expect(message.reload.content).to eq('Original')

      blank_mid_params = {
        messages: [{
          protocol_message: {
            type: "edited_message",
            message_id: nil,
            edited_message: { text: { body: "Some text" } }
          }
        }]
      }
      described_class.new(whatsapp_channel: whatsapp_channel, parsed_params: blank_mid_params).call
      expect(message.reload.content).to eq('Original')
    end
  end
end
