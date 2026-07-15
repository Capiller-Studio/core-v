require 'rails_helper'

RSpec.describe Country, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:states) }
  end

end
