# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WalletTransaction, type: :model do
  let(:account) { create(:account) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:reference).optional }
    it { is_expected.to belong_to(:wallet) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:transaction_type).with_values(topup: 0, deduction: 1, refund: 2) }
  end

  describe 'Scopes' do
    let!(:topup) { create(:wallet_transaction, account: account, transaction_type: :topup, amount: 100) }
    let!(:deduction) { create(:wallet_transaction, account: account, transaction_type: :deduction, amount: 20) }
    let!(:refund) { create(:wallet_transaction, account: account, transaction_type: :refund, amount: 10) }

    it 'filters credits (topup and refund)' do
      expect(described_class.credits).to include(topup, refund)
      expect(described_class.credits).not_to include(deduction)
    end

    it 'filters debits (deduction)' do
      expect(described_class.debits).to include(deduction)
      expect(described_class.debits).not_to include(topup, refund)
    end

    it 'orders recent transactions descending by created_at' do
      expect(described_class.recent.to_a).to eq([refund, deduction, topup])
    end
  end
end
