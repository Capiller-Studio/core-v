require 'rails_helper'

RSpec.describe AssignmentPolicies::Engines::LoadBalancedEngine do
  let(:conversation) { double('Conversation') }
  let(:policy) { double('AssignmentPolicy') }
  let(:service) { described_class.new(conversation: conversation, policy: policy) }

  describe '#select_agent' do
    let(:agent_ids) { ["1", "2", "3"] }
    let(:agent1) { double('User', id: "1") }
    let(:agent2) { double('User', id: "2") }
    let(:agent3) { double('User', id: "3") }

    before do
      stub_const('User', double('UserClass'))
      allow(User).to receive(:find_by).with(id: "1").and_return(agent1)
      allow(User).to receive(:find_by).with(id: "2").and_return(agent2)
      allow(User).to receive(:find_by).with(id: "3").and_return(agent3)
    end

    it 'returns the first agent if only one is eligible' do
      expect(service.send(:select_agent, ["2"])).to eq(agent2)
    end

    it 'selects agent with lowest conversation count and breaks ties with earliest last assignment' do
      where_scope = double('WhereScope')
      group_scope = double('GroupScope')

      allow(Conversation).to receive(:where).with(assignee_id: agent_ids, status: [:active, :snoozed]).and_return(where_scope)
      allow(where_scope).to receive(:group).with(:assignee_id).and_return(group_scope)
      
      # Agent 1 has 5, Agent 2 has 2, Agent 3 has 2
      allow(group_scope).to receive(:count).and_return({ "1" => 5, "2" => 2, "3" => 2 })

      all_where_scope = double('AllWhereScope')
      all_group_scope = double('AllGroupScope')
      
      allow(Conversation).to receive(:where).with(assignee_id: agent_ids).and_return(all_where_scope)
      allow(all_where_scope).to receive(:group).with(:assignee_id).and_return(all_group_scope)
      
      # Agent 2 was assigned more recently, so Agent 3 should win the tie-break
      allow(all_group_scope).to receive(:maximum).with(:updated_at).and_return({ 
        "1" => 1.day.ago,
        "2" => 1.hour.ago,
        "3" => 2.hours.ago 
      })

      # Should select agent 3
      expect(service.send(:select_agent, agent_ids)).to eq(agent3)
    end
  end
end
