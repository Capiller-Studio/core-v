require 'rails_helper'

RSpec.describe Platform::Role, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:staff_roles) }
    it { is_expected.to have_many(:staffs) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:identifier) }
  end

end
