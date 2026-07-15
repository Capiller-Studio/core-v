require 'rails_helper'

RSpec.describe Filter, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:filter_type).with_values(conversation: 0) }
  end

end
