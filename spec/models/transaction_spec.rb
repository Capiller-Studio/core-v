require 'rails_helper'

RSpec.describe Transaction, type: :model do
  subject { build(:transaction) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:subscription).optional }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:transaction_type).with_values(charge: 0, refund: 1, topup: 2, credit: 3) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, completed: 1, failed: 2, refunded: 3) }
    it { is_expected.to define_enum_for(:provider).with_values(stripe: 0, paddle: 1, wallet: 2) }
  end

  describe 'Code Generation' do
    it 'generates a unique identifier with INV prefix' do
      tx = create(:transaction)
      expect(tx.code).to start_with('INV')
    end
  end

  describe '#subtotal' do
    it 'calculates subtotal from line items' do
      tx = build(:transaction, data: {
        'line_items' => [
          { 'amount' => '10.0' },
          { 'amount' => '25.5' }
        ]
      })
      expect(tx.subtotal).to eq(35.5)
    end
  end
end
