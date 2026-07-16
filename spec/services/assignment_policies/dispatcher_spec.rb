require 'rails_helper'

RSpec.describe AssignmentPolicies::Dispatcher do
  let(:account) { double('Account') }
  let(:conversation) { double('Conversation', account: account) }
  let(:policy) { double('AssignmentPolicy', manual?: false, within_business_hours?: true, conditions: {}, strategy: 'round_robin') }
  let(:service) { described_class.new(conversation: conversation) }

  before do
    allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(true)
    allow(AssignmentPolicies::PolicyResolver).to receive(:call).with(conversation: conversation).and_return(policy)
    stub_const('Conversations::RoundRobinAssignment', double('RoundRobinAssignment'))
  end

  describe '#call' do
    it 'falls back to legacy RoundRobin if feature is disabled' do
      allow(account).to receive(:feature_enabled?).with(:assignment_policies).and_return(false)
      
      expect(Conversations::RoundRobinAssignment).to receive(:call).with(conversation: conversation)
      expect(AssignmentPolicies::PolicyResolver).not_to receive(:call)
      
      service.call
    end

    it 'falls back to legacy RoundRobin if no policy is found' do
      allow(AssignmentPolicies::PolicyResolver).to receive(:call).with(conversation: conversation).and_return(nil)
      
      expect(Conversations::RoundRobinAssignment).to receive(:call).with(conversation: conversation)
      
      service.call
    end

    it 'returns if policy is manual' do
      allow(policy).to receive(:manual?).and_return(true)
      
      expect(AssignmentPolicies::Engines::RoundRobinEngine).not_to receive(:call)
      service.call
    end

    it 'returns if outside business hours' do
      allow(policy).to receive(:within_business_hours?).and_return(false)
      
      expect(AssignmentPolicies::Engines::RoundRobinEngine).not_to receive(:call)
      service.call
    end

    it 'returns if conditions do not match' do
      allow(policy).to receive(:conditions).and_return({ "operator" => "AND" })
      allow(AssignmentPolicies::ConditionMatcher).to receive(:call).with(policy: policy, conversation: conversation).and_return(false)
      
      expect(AssignmentPolicies::Engines::RoundRobinEngine).not_to receive(:call)
      service.call
    end

    context 'when delegating to engines' do
      before do
        stub_const('AssignmentPolicies::Engines::RoundRobinEngine', double('RoundRobinEngine'))
        stub_const('AssignmentPolicies::Engines::LoadBalancedEngine', double('LoadBalancedEngine'))
        stub_const('AssignmentPolicies::Engines::SkillsBasedEngine', double('SkillsBasedEngine'))
      end

      it 'delegates to RoundRobinEngine' do
        expect(AssignmentPolicies::Engines::RoundRobinEngine).to receive(:call).with(conversation: conversation, policy: policy)
        service.call
      end

      it 'delegates to LoadBalancedEngine' do
        allow(policy).to receive(:strategy).and_return('load_balanced')
        expect(AssignmentPolicies::Engines::LoadBalancedEngine).to receive(:call).with(conversation: conversation, policy: policy)
        service.call
      end

      it 'delegates to SkillsBasedEngine' do
        allow(policy).to receive(:strategy).and_return('skills_based')
        expect(AssignmentPolicies::Engines::SkillsBasedEngine).to receive(:call).with(conversation: conversation, policy: policy)
        service.call
      end

      it 'raises error for unknown strategy' do
        allow(policy).to receive(:strategy).and_return('unknown')
        expect { service.call }.to raise_error(ArgumentError, /Unknown assignment strategy/)
      end
    end
  end
end
