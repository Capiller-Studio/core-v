require 'rails_helper'

RSpec.describe AssignmentPolicies::CapacityChecker do
  let(:agent_ids) { ['agent_1', 'agent_2', 'agent_3'] }
  let(:policy) { double('Policy', max_conversations_per_agent: max_limit) }
  let(:max_limit) { 5 }
  let(:service) { described_class.new(agent_ids: agent_ids, policy: policy) }

  describe '#call' do
    it 'returns all agent_ids if max_limit is nil' do
      allow(policy).to receive(:max_conversations_per_agent).and_return(nil)
      expect(service.call).to eq(agent_ids)
    end

    it 'returns empty array if agent_ids is empty' do
      service = described_class.new(agent_ids: [], policy: policy)
      expect(service.call).to eq([])
    end

    context 'with limits and active conversations' do
      let(:where_scope) { double('WhereScope') }
      let(:group_scope) { double('GroupScope') }

      before do
        allow(Conversation).to receive(:where).with(assignee_id: agent_ids, status: [:active, :snoozed]).and_return(where_scope)
        allow(where_scope).to receive(:group).with(:assignee_id).and_return(group_scope)
        allow(group_scope).to receive(:count).and_return({
          'agent_1' => 3, # under limit (5)
          'agent_2' => 5, # at limit
          'agent_3' => 6  # over limit
        })
      end

      it 'returns only agents who have current_count < max_limit' do
        result = service.call
        expect(result).to eq(['agent_1'])
      end
      
      it 'returns agents with no active conversations (count 0)' do
        allow(group_scope).to receive(:count).and_return({ 'agent_2' => 5 })
        # agent_1 and agent_3 have 0
        expect(service.call).to match_array(['agent_1', 'agent_3'])
      end
    end
  end
end
