require 'rails_helper'

RSpec.describe Affiliate::PayoutBatch, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:payouts) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processing: 1, funded: 2, failed: 3) }
  end

end
