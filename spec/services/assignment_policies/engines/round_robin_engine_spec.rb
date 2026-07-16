require 'rails_helper'

RSpec.describe AssignmentPolicies::Engines::RoundRobinEngine do
  let(:conversation) { double('Conversation', account_id: 1) }
  let(:policy) { double('AssignmentPolicy', id: 1) }
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
      
      stub_const('RedisUtilities::Helpers', double('RedisHelpers'))
      allow(RedisUtilities::Helpers).to receive(:set)
    end

    it 'returns the first agent if last_assigned is nil' do
      allow(RedisUtilities::Helpers).to receive(:get).and_return(nil)
      
      expect(RedisUtilities::Helpers).to receive(:set).with(anything, "1")
      expect(service.send(:select_agent, agent_ids)).to eq(agent1)
    end

    it 'returns the next agent if last_assigned is present' do
      allow(RedisUtilities::Helpers).to receive(:get).and_return("1")
      
      expect(RedisUtilities::Helpers).to receive(:set).with(anything, "2")
      expect(service.send(:select_agent, agent_ids)).to eq(agent2)
    end

    it 'wraps around to the first agent' do
      allow(RedisUtilities::Helpers).to receive(:get).and_return("3")
      
      expect(RedisUtilities::Helpers).to receive(:set).with(anything, "1")
      expect(service.send(:select_agent, agent_ids)).to eq(agent1)
    end
  end
end
