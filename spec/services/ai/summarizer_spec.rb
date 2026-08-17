# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::Summarizer do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    allow(Ai::Client).to receive(:call).and_return('Customer asked about invoice renewal and agent assisted.')
  end

  describe '#call' do
    it 'returns fallback message when conversation has no messages' do
      result = described_class.call(conversation: conversation, user: user)
      expect(result).to eq('Not enough messages to summarize.')
    end

    it 'summarizes conversation when messages are present' do
      account.with_shard do
        create(:message, conversation: conversation, sender_type: 'Customer', content: 'Where is my invoice?')
        create(:message, conversation: conversation, sender: user, content: 'Sent to your billing email.')
      end

      result = described_class.call(conversation: conversation, user: user)
      expect(result).to eq('Customer asked about invoice renewal and agent assisted.')
      expect(Ai::Client).to have_received(:call).with(
        hash_including(
          account: account,
          user: user,
          action_type: 'conversation_summary',
          model: :lite,
          messages: array_including(
            hash_including(role: 'user', content: match(/Where is my invoice\?/))
          )
        )
      )
    end
  end
end
