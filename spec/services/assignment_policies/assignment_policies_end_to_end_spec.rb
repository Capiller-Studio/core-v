# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment Policies Routing and Backlog Queue End-To-End', type: :service do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, auto_assign: true) }

  let(:agent1) { create(:user, name: 'Agent Alpha') }
  let(:agent2) { create(:user, name: 'Agent Beta') }
  let!(:account_user1) { create(:account_user, account: account, user: agent1) }
  let!(:account_user2) { create(:account_user, account: account, user: agent2) }
  let!(:inbox_user1) { create(:inbox_user, inbox: inbox, user: agent1) }
  let!(:inbox_user2) { create(:inbox_user, inbox: inbox, user: agent2) }

  let(:policy) do
    create(:assignment_policy,
      account: account,
      name: 'Capacity Constrained Round Robin',
      strategy: :round_robin,
      status: :active,
      max_conversations_per_agent: 2,
      respect_business_hours: false
    )
  end
  let!(:policy_inbox) { create(:assignment_policy_inbox, assignment_policy: policy, inbox: inbox) }

  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(true)
    # Both agents online by default in Redis activity helper
    allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return([agent1.id.to_s, agent2.id.to_s])
  end

  describe 'Capacity Limits and Backlog Overflow' do
    it 'distributes conversations evenly until max capacity, then holds excess in backlog' do
      # Pre-fill Agent 1 with 2 active conversations (max capacity reached)
      create_list(:conversation, 2, account: account, inbox: inbox, status: :active, assignee: agent1)

      # Pre-fill Agent 2 with 1 active conversation (1 slot left)
      create(:conversation, account: account, inbox: inbox, status: :active, assignee: agent2)

      # 1. New incoming conversation arrives: Agent 1 full (2/2), Agent 2 has capacity (1/2)
      conv1 = create(:conversation, account: account, inbox: inbox, status: :active, assignee: nil)
      AssignmentPolicies::Dispatcher.call(conversation: conv1)

      expect(conv1.reload.assignee).to eq(agent2)

      # 2. Both agents are now at maximum capacity (Agent 1: 2/2, Agent 2: 2/2)
      conv_overflow = create(:conversation, account: account, inbox: inbox, status: :active, assignee: nil, priority: :urgent)
      AssignmentPolicies::Dispatcher.call(conversation: conv_overflow)

      # Excess conversation remains unassigned in backlog
      expect(conv_overflow.reload.assignee_id).to be_nil
    end
  end

  describe 'QueueDrainer Pipeline on Agent Capacity Liberation' do
    let!(:urgent_backlog) do
      create(:conversation, account: account, inbox: inbox, status: :active, assignee: nil, priority: :urgent)
    end
    let!(:low_backlog) do
      create(:conversation, account: account, inbox: inbox, status: :active, assignee: nil, priority: :low)
    end

    it 'drains backlog prioritizing urgent tickets when agent resolves work' do
      urgent_backlog.update_columns(assignee_id: nil)
      low_backlog.update_columns(assignee_id: nil)

      # Both agents previously maxed out; Agent 1 frees capacity
      allow(AssignmentPolicies::CapacityChecker).to receive(:call) do |args|
        # Return Agent 1 as having freed capacity
        [agent1.id.to_s]
      end

      # Run QueueDrainer
      AssignmentPolicies::QueueDrainer.call(account_id: account.id, inbox_id: inbox.id)

      # Urgent conversation is assigned first to newly freed agent
      expect(urgent_backlog.reload.assignee).to eq(agent1)
    end

    it 'skips draining if all eligible agents are offline' do
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return([])

      expect(AssignmentPolicies::Dispatcher).not_to receive(:call)
      AssignmentPolicies::QueueDrainer.call(account_id: account.id, inbox_id: inbox.id)

      expect(urgent_backlog.reload.assignee_id).to be_nil
    end
  end

  describe 'Business Hours Gating on Dispatch' do
    it 'halts routing when conversation arrives outside configured business hours' do
      bh_group = create(:business_hour_group, account: account, name: 'Strict BH', timezone: 'UTC')
      policy.update!(respect_business_hours: true, business_hour_group: bh_group)

      allow(AssignmentPolicies::BusinessHoursChecker).to receive(:call).and_return(false)

      conv = create(:conversation, account: account, inbox: inbox, status: :active, assignee: nil)
      AssignmentPolicies::Dispatcher.call(conversation: conv)

      expect(conv.reload.assignee_id).to be_nil
    end
  end
end
