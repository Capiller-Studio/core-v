# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Instagram::EditHandler do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:instagram_channel) { create(:channel_instagram, account: account, primary_inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, inbox: inbox, external_id: 'ig_mid_123', content: 'Original content', source: :instagram_direct_message) }

  around do |example|
    account.with_shard do
      example.run
    end
  end

  describe '#call' do
    it 'updates message content and edited_at when message belongs to channel inbox' do
      parsed = double('Parser::InstagramMessageParser', edit_mid: 'ig_mid_123', content: 'Updated content')
      described_class.new(channel: instagram_channel, parsed_message: parsed).call

      expect(message.reload.content).to eq('Updated content')
      expect(message.edited?).to be true
    end

    it 'does nothing if message belongs to a different channel inbox' do
      other_inbox = create(:inbox, account: account)
      other_message = create(:message, account: account, inbox: other_inbox, external_id: 'diff_mid', content: 'Unchanged', source: :whatsapp)
      parsed = double('Parser::InstagramMessageParser', edit_mid: 'diff_mid', content: 'Should not apply')

      described_class.new(channel: instagram_channel, parsed_message: parsed).call
      expect(other_message.reload.content).to eq('Unchanged')
      expect(other_message.edited?).to be false
    end

    it 'does nothing if edit_mid or content is blank' do
      parsed_blank_content = double('Parser::InstagramMessageParser', edit_mid: 'ig_mid_123', content: '')
      described_class.new(channel: instagram_channel, parsed_message: parsed_blank_content).call
      expect(message.reload.content).to eq('Original content')

      parsed_blank_mid = double('Parser::InstagramMessageParser', edit_mid: nil, content: 'Some text')
      described_class.new(channel: instagram_channel, parsed_message: parsed_blank_mid).call
      expect(message.reload.content).to eq('Original content')
    end
  end
end
