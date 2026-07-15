require 'rails_helper'

RSpec.describe State, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:country) }
  end

end
