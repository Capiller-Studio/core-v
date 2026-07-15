require 'rails_helper'

RSpec.describe IdentitySource, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:source_type).with_values(api: 0) }
  end

end
