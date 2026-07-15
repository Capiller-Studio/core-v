require 'rails_helper'

RSpec.describe Note, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:visibility).with_values(personal: 0, global: 1) }
  end

end
