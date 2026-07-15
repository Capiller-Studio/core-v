require 'rails_helper'

RSpec.describe PlanTranslation, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:plan) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:locale) }
    it { is_expected.to validate_presence_of(:display_name) }
  end

end
