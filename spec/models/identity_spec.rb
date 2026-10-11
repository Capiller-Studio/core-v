require 'rails_helper'

RSpec.describe Identity, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:identity_source).optional }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:identity_type) }
    it { is_expected.to validate_presence_of(:identifier) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:identity_type).with_values(custom_api: 0, facebook: 1, instagram: 2, whatsapp: 3, web_widget: 4, mobile_widget: 5) }
  end

end
