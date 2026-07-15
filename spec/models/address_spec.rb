require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:country).optional }
    it { is_expected.to belong_to(:state).optional }
  end

end
