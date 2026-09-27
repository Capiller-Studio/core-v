# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::MessageDebouncer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, ai_status: :ai_active) }
  let(:customer) { create(:customer, account: account) }
  let(:message) do
    create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      sender: customer,
      content: 'Hi',
      source: :web_widget
    )
  end

  before do
    inbox.update!(ai_agent: ai_agent)
    allow(account).to receive(:with_shard).and_call_original
  end

  describe '.buffer_key and .timer_key' do
    it 'includes account_id for multi-shard database isolation' do
      b_key = described_class.buffer_key(account.id, conversation.id)
      t_key = described_class.timer_key(account.id, conversation.id)

      expect(b_key).to eq("AI_BUFFER:#{account.id}:#{conversation.id}")
      expect(t_key).to eq("AI_DEBOUNCE:#{account.id}:#{conversation.id}")
    end
  end

  describe '.debounce_delay_for' do
    it 'returns 0 seconds for email messages' do
      email_message = build(:message, source: :email)
      expect(described_class.debounce_delay_for(email_message)).to eq(0.seconds)
    end

    it 'returns 3.5 seconds for live chat web widget messages' do
      chat_message = build(:message, source: :web_widget)
      expect(described_class.debounce_delay_for(chat_message)).to eq(3.5.seconds)
    end

    it 'returns 3.5 seconds for WhatsApp messages' do
      wa_message = build(:message, source: :whatsapp)
      expect(described_class.debounce_delay_for(wa_message)).to eq(3.5.seconds)
    end

    it 'returns 3.5 seconds for Instagram direct messages' do
      ig_message = build(:message, source: :instagram_direct_message)
      expect(described_class.debounce_delay_for(ig_message)).to eq(3.5.seconds)
    end
  end

  describe 'multi-shard database isolation' do
    it 'generates isolated keys for different accounts with identical conversation ids' do
      account2 = create(:account)
      shared_conv_id = SecureRandom.uuid

      key1 = described_class.buffer_key(account.id, shared_conv_id)
      key2 = described_class.buffer_key(account2.id, shared_conv_id)

      expect(key1).not_to eq(key2)
      expect(key1).to eq("AI_BUFFER:#{account.id}:#{shared_conv_id}")
      expect(key2).to eq("AI_BUFFER:#{account2.id}:#{shared_conv_id}")
    end
  end

  describe '.enqueue' do
    it 'buffers message ID and schedules debounced AgentWorker' do
      expect(RedisUtilities::Helpers).to receive(:push).with(
        "AI_BUFFER:#{account.id}:#{conversation.id}",
        message.id.to_s
      )
      expect(RedisUtilities::Helpers).to receive(:set).with(
        "AI_DEBOUNCE:#{account.id}:#{conversation.id}",
        kind_of(String),
        overwrite: true,
        expiry: 60
      )
      expect(Ai::AgentWorker).to receive(:perform_in).with(
        3.5.seconds,
        account.id,
        conversation.id,
        ai_agent.id,
        kind_of(String)
      )

      described_class.enqueue(message)
    end

    it 'does nothing if conversation is not ai_active' do
      conversation.update!(ai_status: :ai_inactive)

      expect(RedisUtilities::Helpers).not_to receive(:push)
      expect(Ai::AgentWorker).not_to receive(:perform_in)

      described_class.enqueue(message)
    end

    it 'does nothing if inbox has no configured AI agent' do
      inbox.update!(ai_agent: nil)

      expect(RedisUtilities::Helpers).not_to receive(:push)
      expect(Ai::AgentWorker).not_to receive(:perform_in)

      described_class.enqueue(message)
    end
  end

  describe '.ready_to_process?' do
    it 'returns true when the token matches the latest token in Redis' do
      token = Time.current.to_f.to_s
      allow(RedisUtilities::Helpers).to receive(:get).with("AI_DEBOUNCE:#{account.id}:#{conversation.id}").and_return(token)

      expect(described_class.ready_to_process?(account.id, conversation.id, token)).to be true
    end

    it 'returns false when a newer message has updated the token' do
      older_token = '1000.0'
      newer_token = '1003.5'
      allow(RedisUtilities::Helpers).to receive(:get).with("AI_DEBOUNCE:#{account.id}:#{conversation.id}").and_return(newer_token)

      expect(described_class.ready_to_process?(account.id, conversation.id, older_token)).to be false
    end

    it 'returns true if token is blank (legacy or fallback)' do
      expect(described_class.ready_to_process?(account.id, conversation.id, nil)).to be true
    end
  end

  describe '.drain_messages' do
    it 'atomically fetches and clears buffered message IDs inside account shard' do
      b_key = "AI_BUFFER:#{account.id}:#{conversation.id}"
      t_key = "AI_DEBOUNCE:#{account.id}:#{conversation.id}"

      msg2 = create(:message, account: account, conversation: conversation, inbox: inbox, sender: customer, content: 'Help')

      allow(RedisUtilities::Helpers).to receive(:subset).with(b_key, from: 0, to: -1).and_return([message.id.to_s, msg2.id.to_s])
      expect(RedisUtilities::Helpers).to receive(:delete).with(b_key)
      expect(RedisUtilities::Helpers).to receive(:delete).with(t_key)

      messages = described_class.drain_messages(account, conversation)
      expect(messages.map(&:id)).to eq([message.id, msg2.id])
    end

    it 'returns empty array when buffer is empty' do
      allow(RedisUtilities::Helpers).to receive(:subset).and_return([])
      allow(RedisUtilities::Helpers).to receive(:delete)

      expect(described_class.drain_messages(account, conversation)).to eq([])
    end
  end

  describe '.clear!' do
    it 'deletes both buffer and timer keys' do
      b_key = "AI_BUFFER:#{account.id}:#{conversation.id}"
      t_key = "AI_DEBOUNCE:#{account.id}:#{conversation.id}"

      expect(RedisUtilities::Helpers).to receive(:delete).with(b_key)
      expect(RedisUtilities::Helpers).to receive(:delete).with(t_key)

      described_class.clear!(account.id, conversation.id)
    end
  end
end
