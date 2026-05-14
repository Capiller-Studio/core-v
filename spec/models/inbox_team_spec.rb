require 'rails_helper'

RSpec.describe InboxTeam, type: :model do
  subject(:inbox_team) { build(:inbox_team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:team) }
  end

  describe 'Validations' do
    it 'validates uniqueness of team_id scoped to inbox_id' do
      create(:inbox_team)
      is_expected.to validate_uniqueness_of(:team_id).scoped_to(:inbox_id).ignoring_case_sensitivity
    end
  end
end
