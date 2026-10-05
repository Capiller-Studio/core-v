require 'rails_helper'

RSpec.describe Macros::Executor do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, priority: :low) }
  let(:agent) { create(:user) }
  let(:actions) { [ { 'action' => 'set_priority', 'params' => { 'priority' => 'urgent' } } ] }
  let(:macro) { create(:macro, account: account, actions: actions) }

  before do
    create(:account_user, account: account, user: agent)
    allow(Messages::DeliveryWorker).to receive(:perform_async)
  end

  subject(:result) { described_class.call(macro: macro, conversation: conversation, actor: agent) }

  it 'applies the actions synchronously' do
    expect(result).to be_success
    expect(conversation.reload.priority).to eq('urgent')
  end

  it 'logs a manual execution' do
    expect { result }.to change(AutomationExecution, :count).by(1)

    execution = result.execution
    expect(execution.executable).to eq(macro)
    expect(execution.resource).to eq(conversation)
    expect(execution).to be_manual
    expect(execution).to be_success
  end

  it 'records a macro_executed activity attributed to the agent' do
    result
    activity = conversation.activities.find_by(event_key: 'conversation.macro_executed')

    expect(activity).to be_present
    expect(activity.actor).to eq(agent)
  end

  context 'when sending a message' do
    let(:actions) { [ { 'action' => 'send_message', 'params' => { 'content' => 'Thanks!' } } ] }

    it 'sends it as the agent' do
      result
      expect(conversation.messages.last.sender).to eq(agent)
    end
  end

  context 'when some actions fail' do
    let(:actions) do
      [
        { 'action' => 'set_priority', 'params' => { 'priority' => 'high' } },
        { 'action' => 'assign_team', 'params' => { 'team_id' => SecureRandom.uuid } }
      ]
    end

    it 'returns a partial result and keeps successful changes' do
      expect(result).to be_partial
      expect(result.failed_results.size).to eq(1)
      expect(result.succeeded_count).to eq(1)
      expect(conversation.reload.priority).to eq('high')
      expect(result.execution).to be_failed
    end
  end

  context 'when every action fails' do
    let(:actions) { [ { 'action' => 'assign_team', 'params' => { 'team_id' => SecureRandom.uuid } } ] }

    it 'returns a failed result' do
      expect(result).to be_failed
    end
  end

  context 'when the macro is inactive' do
    let(:macro) { create(:macro, account: account, actions: actions, status: :inactive) }

    it 'raises' do
      expect { result }.to raise_error(described_class::InactiveMacroError)
    end
  end
end
