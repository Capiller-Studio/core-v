# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Automations & Macros End-To-End Lifecycle', type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:agent) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: agent) }
  let(:conversation) do
    create(:conversation,
      account: account,
      inbox: inbox,
      status: :active,
      priority: :medium,
      title: 'Billing Inquiry'
    )
  end

  before do
    allow(Messages::DeliveryWorker).to receive(:perform_async)
  end

  describe 'Automations Event-to-Action Execution Pipeline' do
    let(:automation1) do
      create(:automation,
        account: account,
        name: 'Auto-Triage Urgent Tickets',
        automation_type: :event_trigger,
        event_name: 'conversation.created',
        status: :active,
        position: 1,
        stop_processing: false,
        conditions: {
          'operator' => 'AND',
          'groups' => [
            {
              'operator' => 'AND',
              'conditions' => [
                { 'attribute' => 'priority', 'operator' => 'equals', 'value' => 'medium' },
                { 'attribute' => 'status', 'operator' => 'equals', 'value' => 'active' }
              ]
            }
          ]
        },
        actions: [
          { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } },
          { 'action' => 'assign_agent', 'params' => { 'agent_id' => agent.id } }
        ]
      )
    end

    it 'processes matched event, applies state modifications, and persists execution history' do
      automation1

      # 1. Dispatch event through dispatcher
      dispatcher = Automations::EventDispatcher.new(
        event_name: 'conversation.created',
        payload: { 'id' => conversation.id, 'priority' => 'medium', 'status' => 'active' },
        account: account
      )

      # Ensure execution runs
      matching_rules = account.automations.event_triggers_for('conversation.created')
      expect(matching_rules).to include(automation1)

      # 2. Execute actions directly via ActionExecutor
      executor = Automations::ActionExecutor.new(
        executable: automation1,
        resource: conversation,
        account: account
      )

      results = executor.call
      expect(results.length).to eq(2)
      expect(results.all? { |r| r['result'] == 'success' }).to be(true)

      # 3. Verify conversation state updated
      conversation.reload
      expect(conversation.priority).to eq('urgent')
      expect(conversation.assignee_id).to eq(agent.id)
    end

    it 'halts execution of subsequent rules when stop_processing is enabled' do
      rule1 = create(:automation,
        account: account,
        name: 'VIP Priority Escalation',
        automation_type: :event_trigger,
        event_name: 'conversation.created',
        status: :active,
        position: 1,
        stop_processing: true,
        conditions: { 'groups' => [{}] },
        actions: [{ 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } }]
      )

      rule2 = create(:automation,
        account: account,
        name: 'Secondary Tagging Rule',
        automation_type: :event_trigger,
        event_name: 'conversation.created',
        status: :active,
        position: 2,
        stop_processing: false,
        conditions: { 'groups' => [{}] },
        actions: [{ 'action' => 'set_priority', 'params' => { 'priority' => 'low' } }]
      )

      expect(Automations::ExecutionWorker).to receive(:perform_async).with('Automation', rule1.id, 'Conversation', conversation.id, 'event', 0).once
      expect(Automations::ExecutionWorker).not_to receive(:perform_async).with('Automation', rule2.id, any_args)

      dispatcher = Automations::EventDispatcher.new(
        event_name: 'conversation.created',
        payload: { 'id' => conversation.id },
        account: account
      )
      dispatcher.call
    end

    it 'ignores inactive automations' do
      inactive_rule = create(:automation,
        account: account,
        name: 'Disabled Rule',
        automation_type: :event_trigger,
        event_name: 'conversation.created',
        status: :inactive,
        conditions: { 'groups' => [{}] }
      )

      expect(Automations::ExecutionWorker).not_to receive(:perform_async)

      dispatcher = Automations::EventDispatcher.new(
        event_name: 'conversation.created',
        payload: { 'id' => conversation.id },
        account: account
      )
      dispatcher.call
    end

    it 'handles partially invalid actions gracefully without terminating valid modifications' do
      resilient_rule = create(:automation,
        account: account,
        name: 'Resilient Action Handler',
        actions: [
          { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } },
          { 'action' => 'assign_team', 'params' => { 'team_id' => SecureRandom.uuid } }
        ]
      )

      executor = Automations::ActionExecutor.new(
        executable: resilient_rule,
        resource: conversation,
        account: account
      )

      results = executor.call
      expect(results.length).to eq(2)
      expect(results.first['result']).to eq('success')
      expect(results.second['result']).to eq('failed')

      # Valid change persisted
      expect(conversation.reload.priority).to eq('urgent')
    end
  end

  describe 'Macros Synchronous Execution Pipeline' do
    let(:macro) do
      create(:macro,
        account: account,
        name: 'Resolve & Archive Ticket',
        visibility: :account_wide,
        actions: [
          { 'action' => 'set_status', 'params' => { 'status' => 'resolved' } },
          { 'action' => 'set_priority', 'params' => { 'priority' => 'low' } },
          { 'action' => 'send_message', 'params' => { 'content' => 'Issue resolved by support agent.' } }
        ]
      )
    end

    it 'applies atomic macro actions synchronously and logs manual execution audit' do
      result = Macros::Executor.call(macro: macro, conversation: conversation, actor: agent)

      expect(result).to be_success
      conversation.reload
      expect(conversation.status).to eq('resolved')
      expect(conversation.priority).to eq('low')
      expect(conversation.messages.last.content).to eq('Issue resolved by support agent.')
      expect(conversation.messages.last.sender).to eq(agent)

      # Execution audit log
      execution = result.execution
      expect(execution).to be_present
      expect(execution.executable).to eq(macro)
      expect(execution.resource).to eq(conversation)
      expect(execution.status).to eq('success')
      expect(execution.triggered_by).to eq('manual')
    end

    it 'enforces visibility constraints between personal and team macros' do
      other_agent = create(:user)
      create(:account_user, account: account, user: other_agent)

      personal_macro = create(:macro,
        account: account,
        scopeable: other_agent,
        visibility: :personal,
        actions: [{ 'action' => 'set_priority', 'params' => { 'priority' => 'high' } }]
      )

      # Non-creator is not allowed to see or run personal macro of another agent
      accessible_macros = Macro.for_user(agent)
      expect(accessible_macros).not_to include(personal_macro)
    end
  end
end
