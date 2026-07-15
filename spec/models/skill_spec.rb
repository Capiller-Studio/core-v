require 'rails_helper'

RSpec.describe Skill, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:user_skills) }
    it { is_expected.to have_many(:users) }
  end

  describe 'Validations' do
    subject { create(:skill) }
    
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:account_id) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:skill_type).with_values(general: 0, language: 1, product: 2, technical: 3) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }

    it '.by_type returns skills of specific type' do
      general_skill = create(:skill, account: account, skill_type: :general)
      language_skill = create(:skill, account: account, skill_type: :language)

      expect(Skill.by_type(:general)).to include(general_skill)
      expect(Skill.by_type(:general)).not_to include(language_skill)
    end

    it '.ordered returns skills ordered by type and name' do
      s1 = create(:skill, account: account, skill_type: :language, name: 'B')
      s2 = create(:skill, account: account, skill_type: :general, name: 'A')
      s3 = create(:skill, account: account, skill_type: :language, name: 'C')

      expect(Skill.where(id: [s1.id, s2.id, s3.id]).ordered).to eq([s2, s1, s3])
    end
  end
end
