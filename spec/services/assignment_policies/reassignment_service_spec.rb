require 'rails_helper'

RSpec.describe AssignmentPolicies::ReassignmentService do
  let(:user) { double('User') }
  let(:account) { double('Account') }
  let(:service) { described_class.new(user: user, account: account) }

  describe '#call' do
    let(:conversation1) { double('Conversation') }
    let(:conversation2) { double('Conversation') }
    let(:scope) { double('Scope') }
    let(:policy1) { double('Policy', reassign_on_offline?: true) }
    let(:policy2) { double('Policy', reassign_on_offline?: false) }

    before do
      allow(Conversation).to receive(:where).with(assignee: user, account: account, status: [:active, :snoozed]).and_return(scope)
      allow(scope).to receive(:find_each).and_yield(conversation1).and_yield(conversation2)
      
      allow(AssignmentPolicies::PolicyResolver).to receive(:call).with(conversation: conversation1).and_return(policy1)
      allow(AssignmentPolicies::PolicyResolver).to receive(:call).with(conversation: conversation2).and_return(policy2)
      
      stub_const('AssignmentPolicies::Dispatcher', double('Dispatcher'))
    end

    it 'unassigns and dispatches conversations if policy reassign_on_offline is true' do
      expect(conversation1).to receive(:unassign!)
      expect(AssignmentPolicies::Dispatcher).to receive(:call).with(conversation: conversation1)
      
      expect(conversation2).not_to receive(:unassign!)
      expect(AssignmentPolicies::Dispatcher).not_to receive(:call).with(conversation: conversation2)

      service.call
    end

    it 'handles nil policy by skipping reassignment' do
      allow(AssignmentPolicies::PolicyResolver).to receive(:call).with(conversation: conversation1).and_return(nil)
      
      expect(conversation1).not_to receive(:unassign!)
      expect(AssignmentPolicies::Dispatcher).not_to receive(:call).with(conversation: conversation1)
      
      service.call
    end
  end
end
