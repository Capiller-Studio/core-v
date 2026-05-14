require 'rails_helper'

RSpec.describe Macro, type: :model do
  subject { build(:macro) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:scopeable).optional }
    it { is_expected.to have_many(:executions).dependent(:destroy) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:visibility).with_values(account_wide: 0, personal: 1, team: 2) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }

    describe '#scopeable_matches_visibility' do
      let(:account) { create(:account) }
      let(:user) { create(:user) }
      let(:team) { create(:team, account: account) }

      it 'is valid for account_wide with no scopeable' do
        macro = build(:macro, account: account, visibility: :account_wide, scopeable: nil)
        expect(macro).to be_valid
      end

      it 'is invalid for account_wide with scopeable' do
        macro = build(:macro, account: account, visibility: :account_wide, scopeable: user)
        expect(macro).not_to be_valid
        expect(macro.errors[:scopeable]).to include('must be blank for account-wide macros')
      end

      it 'is valid for personal with user scopeable' do
        macro = build(:macro, account: account, visibility: :personal, scopeable: user)
        expect(macro).to be_valid
      end

      it 'is invalid for personal with team scopeable' do
        macro = build(:macro, account: account, visibility: :personal, scopeable: team)
        expect(macro).not_to be_valid
        expect(macro.errors[:scopeable]).to include('must be a User for personal macros')
      end

      it 'is valid for team with team scopeable' do
        macro = build(:macro, account: account, visibility: :team, scopeable: team)
        expect(macro).to be_valid
      end
    end
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:team) { create(:team, account: account) }
    
    let!(:global_macro) { create(:macro, account: account, visibility: :account_wide) }
    let!(:personal_macro) { create(:macro, account: account, visibility: :personal, scopeable: user) }
    let!(:team_macro) { create(:macro, account: account, visibility: :team, scopeable: team) }
    let!(:system_macro) { create(:macro, account: account, is_system: true) }

    describe '.for_user' do
      it 'returns global, personal and specific team macros' do
        results = Macro.for_user(user, team_ids: [team.id])
        expect(results).to include(global_macro, personal_macro, team_macro, system_macro)
      end

      it 'does not return other personal macros' do
        other_user = create(:user)
        other_macro = create(:macro, account: account, visibility: :personal, scopeable: other_user)
        results = Macro.for_user(user)
        expect(results).not_to include(other_macro)
      end
    end
  end
end
