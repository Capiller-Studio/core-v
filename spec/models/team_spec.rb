require 'rails_helper'

RSpec.describe Team, type: :model do
  subject { build(:team) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0) }
  end
end
