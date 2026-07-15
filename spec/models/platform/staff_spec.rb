require 'rails_helper'

RSpec.describe Platform::Staff, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:comments) }
    it { is_expected.to have_many(:roles) }
    it { is_expected.to have_many(:staff_roles) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1, deactivated: 2) }
  end

end
