# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::ConversationClassifierWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:customer_message) { create(:message, account: account, conversation: conversation, sender_type: 'Customer', content: 'I am really frustrated with the service!') }

  before do
    allow(account).to receive(:feature_enabled?).with(:ai_copilot).and_return(true)
    allow(account).to receive(:feature_enabled?).with(:ai_agent).and_return(false)
    allow(Conversation).to receive(:find_by).with(id: conversation.id).and_return(conversation)
    allow(conversation).to receive(:account).and_return(account)
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    it 'classifies sentiment and priority using Ai::Client and updates conversation' do
      ai_response = {
        sentiment: 'negative',
        priority: 'urgent',
        category: 'unknown'
      }.to_json

      expect(Ai::Client).to receive(:call).with(
        hash_including(
          account: account,
          action_type: 'conversation_classification',
          model: :lite,
          response_format: 'json_object'
        )
      ).and_return(ai_response)

      described_class.new.perform(conversation.id)

      conversation.reload
      expect(conversation.ai_metadata['sentiment']).to eq('negative')
      expect(conversation.priority).to eq('urgent')
    end

    it 'applies label if inbox has auto labelling enabled and category matches an active label' do
      label = create(:label, account: account, title: 'Billing')
      inbox.update!(ai_auto_labelling: true)

      ai_response = {
        sentiment: 'neutral',
        priority: 'normal',
        category: 'Billing'
      }.to_json

      allow(Ai::Client).to receive(:call).and_return(ai_response)

      expect {
        described_class.new.perform(conversation.id)
      }.to change { conversation.applied_labels.count }.by(1)

      expect(conversation.applied_labels.last.label).to eq(label)
    end

    it 'skips if conversation is already classified' do
      conversation.update!(ai_metadata: { 'sentiment' => 'positive' })
      expect(Ai::Client).not_to receive(:call)

      described_class.new.perform(conversation.id)
    end

    it 'handles AiInsufficientBalanceError gracefully' do
      stub_const('AiInsufficientBalanceError', Class.new(StandardError))
      allow(Ai::Client).to receive(:call).and_raise(AiInsufficientBalanceError.new('No credits'))

      expect { described_class.new.perform(conversation.id) }.not_to raise_error
    end
  end
end
