# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::Drafter do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    allow(Ai::Client).to receive(:call).and_return('Drafted response for customer')
    account.with_shard do
      create(:message, conversation: conversation, sender_type: 'Customer', content: 'How do I reset my password?')
      create(:message, conversation: conversation, sender: user, content: 'Have you clicked forgot password?')
    end
  end

  describe '#call' do
    it 'formats conversation history and calls Ai::Client' do
      result = described_class.call(
        conversation: conversation,
        user: user,
        instruction: 'Explain steps to reset password via email link'
      )

      expect(result).to eq('Drafted response for customer')
      expect(Ai::Client).to have_received(:call).with(
        hash_including(
          account: account,
          user: user,
          action_type: 'draft_reply',
          model: :lite,
          messages: array_including(
            hash_including(role: 'user', content: match(/How do I reset my password\?/))
          )
        )
      )
    end
  end
end
