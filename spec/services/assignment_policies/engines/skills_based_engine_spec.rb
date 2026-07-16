require 'rails_helper'

RSpec.describe AssignmentPolicies::Engines::SkillsBasedEngine do
  let(:conversation) { double('Conversation') }
  let(:policy) { double('AssignmentPolicy', configurations: configurations) }
  let(:service) { described_class.new(conversation: conversation, policy: policy) }

  describe '#select_agent' do
    let(:agent_ids) { ["1", "2", "3"] }
    let(:agent2) { double('User', id: "2") }

    before do
      stub_const('User', double('UserClass'))
      allow(User).to receive(:find_by).with(id: "1").and_return(double('User', id: "1"))
      allow(User).to receive(:find_by).with(id: "2").and_return(agent2)
      allow(User).to receive(:find_by).with(id: "3").and_return(double('User', id: "3"))

      allow(service).to receive(:load_balanced_select).and_wrap_original do |m, ids|
        User.find_by(id: ids.first)
      end
    end

    context 'when no skills configured' do
      let(:configurations) { {} }

      it 'falls back to load balanced selection' do
        expect(service).to receive(:load_balanced_select).with(agent_ids)
        service.send(:select_agent, agent_ids)
      end
    end

    context 'with required skills' do
      let(:configurations) { { "required_skill_ids" => [10, 20], "skill_match_mode" => "all" } }
      let(:user_skills_scope) { double('UserSkillsScope') }

      before do
        stub_const('UserSkill', double('UserSkillClass'))
        allow(UserSkill).to receive(:where).with(user_id: agent_ids, skill_id: [10, 20]).and_return(user_skills_scope)
        allow(user_skills_scope).to receive(:group).with(:user_id).and_return(user_skills_scope)
      end

      it 'matches agents with all skills' do
        allow(user_skills_scope).to receive(:having).and_return(user_skills_scope)
        allow(user_skills_scope).to receive(:pluck).with(:user_id).and_return([2])
        
        expect(service).to receive(:load_balanced_select).with(["2"]).and_return(agent2)
        expect(service.send(:select_agent, agent_ids)).to eq(agent2)
      end

      it 'handles fallback when no agents match all skills' do
        allow(user_skills_scope).to receive(:having).and_return(user_skills_scope)
        allow(user_skills_scope).to receive(:pluck).with(:user_id).and_return([])

        # Fallback best_match logic
        allow(user_skills_scope).to receive(:count).and_return({ 1 => 1, 2 => 1, 3 => 0 })
        
        # Best matches are 1 and 2
        expect(service).to receive(:load_balanced_select).with(["1", "2"]).and_call_original
        service.send(:select_agent, agent_ids)
      end
    end
  end
end
