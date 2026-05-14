require 'rails_helper'

RSpec.describe TeamUser, type: :model do
  subject(:team_user) { build(:team_user) }

  describe 'Associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:role).with_values(member: 0, lead: 1) }
  end

  describe 'Validations' do
    describe 'uniqueness' do
      let(:account) { create(:account) }
      let(:team) { create(:team, account: account) }
      let(:user) { create(:user) }
      let!(:account_user) { create(:account_user, account: account, user: user) }
      let!(:existing_team_user) { create(:team_user, team: team, user: user) }

      it 'validates uniqueness of user_id scoped to team_id' do
        new_user = create(:user)
        create(:account_user, account: account, user: new_user)
        new_team_user = build(:team_user, team: team, user: new_user)
        
        expect(new_team_user).to validate_uniqueness_of(:user_id)
          .scoped_to(:team_id)
          .with_message('is already a member of this team')
          .ignoring_case_sensitivity
      end
    end

    describe '#user_belongs_to_team_account' do
      let(:account) { create(:account) }
      let(:team) { create(:team, account: account) }
      let(:user) { create(:user) }

      it 'is valid if user belongs to the same account' do
        create(:account_user, account: account, user: user)
        tu = build(:team_user, team: team, user: user)
        expect(tu).to be_valid
      end

      it 'is invalid if user does not belong to the same account' do
        tu = build(:team_user, team: team, user: user)
        expect(tu).not_to be_valid
        expect(tu.errors[:user]).to include('does not belong to the same account as this team')
      end
    end
  end
end
