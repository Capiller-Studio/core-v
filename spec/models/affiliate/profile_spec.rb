require 'rails_helper'

RSpec.describe Affiliate::Profile, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:commissions) }
    it { is_expected.to have_many(:payouts) }
    it { is_expected.to have_many(:referrals) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:referral_code) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:payment_method_type).with_values(bank: 0) }
  end

end
