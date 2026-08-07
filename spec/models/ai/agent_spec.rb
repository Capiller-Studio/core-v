require 'rails_helper'

RSpec.describe Ai::Agent, type: :model do
  subject(:agent) { build(:ai_agent) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal).class_name("HelpCenter::Portal").optional }
    it { is_expected.to have_many(:inboxes).with_foreign_key('ai_agent_id').dependent(:nullify) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
    it { is_expected.to define_enum_for(:agent_type).with_values(help_center_bot: 0, custom: 1) }
    it { is_expected.to define_enum_for(:tone).with_values(professional: 0, friendly: 1, neutral: 2, concise: 3) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:max_exchanges).is_greater_than(0).is_less_than_or_equal_to(20) }
    it { is_expected.to validate_numericality_of(:confidence_threshold).is_greater_than_or_equal_to(0.0).is_less_than_or_equal_to(1.0) }
  end

  describe 'Translateable Fields' do
    it 'translates greeting_message' do
      agent.save!
      I18n.with_locale(:es) do
        agent.greeting_message = 'Hola'
        agent.save!
        expect(agent.greeting_message).to eq('Hola')
      end
    end
  end

  describe '#active_and_configured?' do
    it 'returns true when active' do
      agent.status = :active
      expect(agent.active_and_configured?).to be true
    end

    it 'returns false when inactive' do
      agent.status = :inactive
      expect(agent.active_and_configured?).to be false
    end
  end

  describe '#resolution_rate' do
    it 'returns 0 if total_conversations is zero' do
      agent.total_conversations = 0
      expect(agent.resolution_rate).to eq(0)
    end

    it 'calculates resolution rate properly' do
      agent.total_conversations = 100
      agent.total_resolutions = 25
      expect(agent.resolution_rate).to eq(25.0)
    end
  end

  describe '#handoff_rate' do
    it 'returns 0 if total_conversations is zero' do
      agent.total_conversations = 0
      expect(agent.handoff_rate).to eq(0)
    end

    it 'calculates handoff rate properly' do
      agent.total_conversations = 100
      agent.total_handoffs = 15
      expect(agent.handoff_rate).to eq(15.0)
    end
  end

  describe '#event_payload' do
    it 'returns the event payload hash' do
      agent.save!
      payload = agent.event_payload
      expect(payload[:id]).to eq(agent.id)
      expect(payload[:name]).to eq(agent.name)
      expect(payload[:type]).to eq('ai_agent')
    end
  end
end
