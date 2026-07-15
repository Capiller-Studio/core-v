require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:owner) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:token_type).with_values(api_key: 0, magic_link: 1) }
  end

end
