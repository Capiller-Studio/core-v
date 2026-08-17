# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::ThankYouDetectorWorker, type: :worker do
  let(:account) { create(:account) }
  let(:customer) { create(:customer, account: account) }
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, account: account, status: :active, status_changed_at: Time.current) }
  let(:message) { create(:message, account: account, conversation: conversation, sender: customer, content: 'Thank you!', created_at: Time.current) }

  describe '#perform' do
    it 'fast-path detects obvious thank you phrases and resolves active conversation' do
      expect(Ai::Client).not_to receive(:call)

      described_class.new.perform(message.id)

      conversation.reload
      expect(conversation.status).to eq('resolved')
      expect(message.reload.ai_metadata['auto_resolved']).to be(true)
    end

    it 'uses AI client when not an obvious regex match and resolves if classified as thank you' do
      non_obvious_msg = create(:message,
        account: account,
        conversation: conversation,
        sender: customer,
        content: 'I appreciate all the assistance from your team earlier today, wonderful job.',
        created_at: Time.current
      )

      ai_response = { is_thank_you_or_ooo: true }.to_json
      expect(Ai::Client).to receive(:call).with(
        hash_including(
          account: account,
          action_type: 'thank_you_detection',
          model: :lite,
          response_format: 'json_object'
        )
      ).and_return(ai_response)

      described_class.new.perform(non_obvious_msg.id)

      conversation.reload
      expect(conversation.status).to eq('resolved')
      expect(non_obvious_msg.reload.ai_metadata['auto_resolved']).to be(true)
    end

    it 'does not resolve conversation if AI client returns is_thank_you_or_ooo false' do
      question_msg = create(:message,
        account: account,
        conversation: conversation,
        sender: customer,
        content: 'Thanks, but I also have one more question regarding invoice #456.',
        created_at: Time.current
      )

      ai_response = { is_thank_you_or_ooo: false }.to_json
      allow(Ai::Client).to receive(:call).and_return(ai_response)

      described_class.new.perform(question_msg.id)

      conversation.reload
      expect(conversation.status).to eq('active')
      expect(question_msg.reload.ai_metadata).to be_blank
    end

    it 'returns early if message is not incoming' do
      outgoing_msg = create(:message, account: account, conversation: conversation, sender: user, content: 'Thank you')
      expect(Ai::Client).not_to receive(:call)

      described_class.new.perform(outgoing_msg.id)
      expect(conversation.reload.status).to eq('active')
    end
  end
end
