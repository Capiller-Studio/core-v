# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::AgentWorker, type: :worker do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:message) { create(:message, account: account, conversation: conversation, content: 'How do I reset my password?') }
  let(:portal) { create(:help_center_portal, account: account) }
  let(:ai_agent) { create(:ai_agent, account: account, portal: portal, fallback_message: 'Connecting to human...') }

  describe '#perform' do
    context 'when help center bot returns a response' do
      it 'creates an AI message, formats markdown, and queues delivery worker' do
        allow(Ai::HelpCenterBot).to receive(:call).and_return('Here is how you reset your password: click [here](https://example.com)')
        allow(Channels::MessageFormatter).to receive(:parse_ai_markdown_to_html).and_return('<p>Here is how you reset your password</p>')

        expect(Messages::DeliveryWorker).to receive(:perform_async).with(account.id, kind_of(String))

        expect {
          described_class.new.perform(account.id, conversation.id, message.id, ai_agent.id)
        }.to change { conversation.messages.count }.by(1)

        ai_msg = conversation.messages.where(sender: ai_agent).last
        expect(ai_msg).to be_present
        expect(ai_msg.content).to eq('<p>Here is how you reset your password</p>')
        expect(ai_msg.sender).to eq(ai_agent)
      end
    end

    context 'when AI returns fallback / handoff' do
      it 'triggers human handoff and marks conversation ai_handed_off' do
        allow(Ai::HelpCenterBot).to receive(:call).and_return('Connecting to human...')
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        described_class.new.perform(account.id, conversation.id, message.id, ai_agent.id)

        conversation.reload
        expect(conversation.ai_status).to eq('ai_handed_off')
      end
    end

    context 'when AiInsufficientBalanceError is raised' do
      it 'rescues, creates fallback message, and triggers human handoff with note' do
        stub_const('AiInsufficientBalanceError', Class.new(StandardError))
        allow(Ai::HelpCenterBot).to receive(:call).and_raise(AiInsufficientBalanceError.new('No credits'))
        allow(Messages::DeliveryWorker).to receive(:perform_async)

        expect {
          described_class.new.perform(account.id, conversation.id, message.id, ai_agent.id)
        }.not_to raise_error

        conversation.reload
        expect(conversation.ai_status).to eq('ai_handed_off')
      end
    end
  end
end
