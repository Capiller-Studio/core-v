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

    describe 'individual scopes' do
      it '.account_wide_macros returns only account wide' do
        expect(Macro.account_wide_macros).to include(global_macro)
        expect(Macro.account_wide_macros).not_to include(system_macro, personal_macro, team_macro)
      end

      it '.personal_macros returns for user' do
        expect(Macro.personal_macros(user)).to include(personal_macro)
        expect(Macro.personal_macros(user)).not_to include(global_macro, team_macro)
      end

      it '.team_macros returns for team' do
        expect(Macro.team_macros(team)).to include(team_macro)
        expect(Macro.team_macros(team)).not_to include(global_macro, personal_macro)
      end

      it '.system_macros returns system macros' do
        expect(Macro.system_macros).to include(system_macro)
        expect(Macro.system_macros).not_to include(global_macro)
      end
    end
  end

  describe 'Instance Methods' do
    let(:account) { create(:account) }
    let(:user) { create(:user) }
    let(:team) { create(:team, account: account) }

    let(:personal_macro) { create(:macro, account: account, visibility: :personal, scopeable: user) }
    let(:team_macro) { create(:macro, account: account, visibility: :team, scopeable: team) }

    describe '#owner' do
      it 'returns scopeable if personal' do
        expect(personal_macro.owner).to eq(user)
      end

      it 'returns nil if not personal' do
        expect(team_macro.owner).to be_nil
      end
    end

    describe '#team' do
      it 'returns scopeable if team' do
        expect(team_macro.team).to eq(team)
      end

      it 'returns nil if not team' do
        expect(personal_macro.team).to be_nil
      end
    end

    describe '#owned_by?' do
      it 'returns true if user matches' do
        expect(personal_macro.owned_by?(user)).to be true
      end

      it 'returns false if user does not match' do
        other_user = create(:user)
        expect(personal_macro.owned_by?(other_user)).to be false
      end

      it 'returns false if not personal' do
        expect(team_macro.owned_by?(user)).to be false
      end
    end

    describe '#duplicate' do
      it 'duplicates the macro with new name and inactive status' do
        copy = personal_macro.duplicate
        expect(copy.name).to eq("#{personal_macro.name} (copy)")
        expect(copy.status).to eq('inactive')
        expect(copy.is_system).to be false
        expect(copy.account_id).to eq(account.id)
      end

      it 'uses provided name if passed' do
        copy = personal_macro.duplicate(new_name: 'Custom Name')
        expect(copy.name).to eq('Custom Name')
      end
    end
  end
end
