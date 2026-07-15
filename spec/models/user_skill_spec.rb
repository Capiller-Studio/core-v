require 'rails_helper'

RSpec.describe UserSkill, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:skill) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:skill) { create(:skill, account: account) }

    before do
      create(:account_user, account: account, user: user)
    end

    subject { create(:user_skill, account: account, user: user, skill: skill) }

    it { is_expected.to validate_presence_of(:proficiency) }

    it 'validates uniqueness of user_id scoped to skill_id' do
      expect(subject).to be_valid
      duplicate = build(:user_skill, account: subject.account, user: subject.user, skill: subject.skill)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end

    it 'validates user_belongs_to_account' do
      other_user = create(:user)
      invalid_user_skill = build(:user_skill, account: account, user: other_user, skill: skill)
      
      expect(invalid_user_skill).not_to be_valid
      expect(invalid_user_skill.errors[:user]).to include('is invalid')
    end
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:proficiency).with_values(beginner: 1, intermediate: 2, expert: 3) }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:skill) { create(:skill, account: account) }

    before do
      create(:account_user, account: account, user: user)
    end

    it '.for_user returns user skills for user' do
      us = create(:user_skill, account: account, user: user, skill: skill)
      expect(UserSkill.for_user(user)).to include(us)
    end

    it '.for_skill returns user skills for skill' do
      us = create(:user_skill, account: account, user: user, skill: skill)
      expect(UserSkill.for_skill(skill)).to include(us)
    end

    it '.with_min_proficiency returns correct user skills' do
      us1 = create(:user_skill, account: account, user: user, skill: skill, proficiency: :beginner)
      
      skill2 = create(:skill, account: account)
      us2 = create(:user_skill, account: account, user: user, skill: skill2, proficiency: :expert)

      expect(UserSkill.with_min_proficiency(:intermediate)).to include(us2)
      expect(UserSkill.with_min_proficiency(:intermediate)).not_to include(us1)
    end
  end
end
