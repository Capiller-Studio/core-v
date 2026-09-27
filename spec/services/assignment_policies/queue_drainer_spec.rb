# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentPolicies::QueueDrainer do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, auto_assign: true) }
  let(:manual_inbox) { create(:inbox, account: account, flags: 0) } # auto_assign disabled
  let!(:conv1) { create(:conversation, account: account, inbox: inbox, status: :active, assignee_id: nil, priority: :low) }
  let!(:conv2) { create(:conversation, account: account, inbox: inbox, status: :active, assignee_id: nil, priority: :urgent) }
  let!(:manual_conv) { create(:conversation, account: account, inbox: manual_inbox, status: :active, assignee_id: nil, priority: :urgent) }
  let!(:resolved_conv) { create(:conversation, account: account, inbox: inbox, status: :resolved, assignee_id: nil) }
  let!(:assigned_conv) { create(:conversation, account: account, inbox: inbox, status: :active, assignee: create(:user)) }

  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return(['agent-1'])
  end

  describe '#call' do
    it 'dispatches active unassigned conversations in priority order' do
      dispatched = []
      allow(AssignmentPolicies::Dispatcher).to receive(:call) do |args|
        dispatched << args[:conversation].id
      end

      described_class.call(account_id: account.id, inbox_id: inbox.id)

      expect(dispatched).to eq([conv2.id, conv1.id])
    end

    it 'exits early without querying or dispatching if no agents are active in Redis' do
      allow(Utilities::ActivityHelpers).to receive(:available_user_ids).with(account.id).and_return([])
      expect(AssignmentPolicies::Dispatcher).not_to receive(:call)

      described_class.call(account_id: account.id, inbox_id: inbox.id)
    end

    it 'skips inboxes where auto_assign is disabled' do
      dispatched = []
      allow(AssignmentPolicies::Dispatcher).to receive(:call) do |args|
        dispatched << args[:conversation].id
      end

      described_class.call(account_id: account.id)

      expect(dispatched).not_to include(manual_conv.id)
      expect(dispatched).to include(conv1.id, conv2.id)
    end

    it 'skips conversations where should_auto_assign? is false' do
      allow_any_instance_of(Conversation).to receive(:should_auto_assign?).and_return(false)
      expect(AssignmentPolicies::Dispatcher).not_to receive(:call)

      described_class.call(account_id: account.id, inbox_id: inbox.id)
    end

    it 'skips already assigned or resolved conversations' do
      dispatched = []
      allow(AssignmentPolicies::Dispatcher).to receive(:call) do |args|
        dispatched << args[:conversation].id
      end

      described_class.call(account_id: account.id, inbox_id: inbox.id)

      expect(dispatched).not_to include(resolved_conv.id)
      expect(dispatched).not_to include(assigned_conv.id)
    end

    it 'clears backlog flag when all conversations are assigned' do
      allow(AssignmentPolicies::Dispatcher).to receive(:call) do |args|
        args[:conversation].update!(assignee: create(:user))
      end

      described_class.call(account_id: account.id, inbox_id: inbox.id)

      expect(AssignmentPolicies::BacklogTracker.backlog_pending?(account.id)).to be false
    end

    it 'marks backlog as existing when unassigned conversations remain' do
      allow(AssignmentPolicies::Dispatcher).to receive(:call) # does not assign

      described_class.call(account_id: account.id, inbox_id: inbox.id)

      expect(AssignmentPolicies::BacklogTracker.backlog_pending?(account.id)).to be true
    end

    it 'returns gracefully if account not found' do
      expect(AssignmentPolicies::Dispatcher).not_to receive(:call)
      described_class.call(account_id: SecureRandom.uuid)
    end
  end
end
