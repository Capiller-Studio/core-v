require 'rails_helper'

RSpec.describe WalletTransaction, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:reference).optional }
    it { is_expected.to belong_to(:wallet) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:transaction_type).with_values(topup: 0, deduction: 1, refund: 2) }
  end

end
