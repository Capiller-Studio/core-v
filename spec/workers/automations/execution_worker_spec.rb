# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Automations::ExecutionWorker, type: :worker do
  let(:account) { create(:account) }
  let(:automation) { create(:automation, account: account, status: :active, automation_type: :event_trigger) }
  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    it 'executes actions, records an execution log, and cascades event dispatch' do
      action_results = [{ 'action' => 'assign_team', 'result' => 'success' }]
      expect(Automations::ActionExecutor).to receive(:call).with(
        executable: automation,
        resource: conversation,
        account: account
      ).and_return(action_results)

      expect(Automations::EventDispatcher).to receive(:call).with(
        event_name: 'conversation.updated',
        payload: kind_of(Hash),
        account: account,
        cascade_depth: 1
      )

      expect {
        described_class.new.perform('Automation', automation.id, 'Conversation', conversation.id, 'event', 0)
      }.to change(AutomationExecution, :count).by(1)

      execution = AutomationExecution.order(:created_at).last
      expect(execution.status).to eq('success')
      expect(execution.executed_actions).to eq(action_results)
    end

    it 'records failed status if an action failed' do
      action_results = [{ 'action' => 'send_webhook', 'result' => 'failed', 'error' => 'Connection timeout' }]
      allow(Automations::ActionExecutor).to receive(:call).and_return(action_results)
      allow(Automations::EventDispatcher).to receive(:call)

      expect {
        described_class.new.perform('Automation', automation.id, 'Conversation', conversation.id)
      }.to change(AutomationExecution, :count).by(1)

      execution = AutomationExecution.order(:created_at).last
      expect(execution.status).to eq('failed')
      expect(execution.error_message).to eq('Connection timeout')
    end

    it 'returns early if executable is not active' do
      automation.update!(status: :inactive)
      expect(Automations::ActionExecutor).not_to receive(:call)

      described_class.new.perform('Automation', automation.id, 'Conversation', conversation.id)
    end
  end
end
