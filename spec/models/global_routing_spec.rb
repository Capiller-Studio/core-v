require 'rails_helper'

RSpec.describe GlobalRouting, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:route_type) }
    it { is_expected.to validate_presence_of(:route_value) }
    it { is_expected.to validate_presence_of(:shard_key) }
  end

end
