require 'rails_helper'

RSpec.describe Ai::AgentTranslation, type: :model do
  subject { build(:ai_agent_translation) }

  describe 'Associations' do
    it { is_expected.to belong_to(:agent).class_name("Ai::Agent") }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:locale) }
    
    it 'validates uniqueness of locale scoped to agent_id' do
      translation = create(:ai_agent_translation, locale: 'en')
      duplicate = build(:ai_agent_translation, agent: translation.agent, locale: 'en')
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:locale]).to include("has already been taken")
    end
  end
end
