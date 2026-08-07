require 'rails_helper'

RSpec.describe Ai::WalletTransaction, type: :model do
  subject { build(:ai_wallet_transaction) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:wallet).class_name("Ai::Wallet").with_foreign_key("ai_wallet_id") }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:transaction_type).with_values(topup: 0, deduction: 1, refund: 2) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than(0) }
    
    it { is_expected.to validate_presence_of(:balance_after) }
    it { is_expected.to validate_numericality_of(:balance_after).only_integer }
  end

  describe 'Scopes' do
    let(:account) { create(:account) }
    let(:wallet) { account.ai_wallet }
    let!(:topup_tx) { create(:ai_wallet_transaction, account: account, wallet: wallet, transaction_type: :topup) }
    let!(:deduction_tx) { create(:ai_wallet_transaction, account: account, wallet: wallet, transaction_type: :deduction) }
    let!(:refund_tx) { create(:ai_wallet_transaction, account: account, wallet: wallet, transaction_type: :refund) }

    describe '.credits' do
      it 'returns topups and refunds' do
        expect(Ai::WalletTransaction.credits).to include(topup_tx, refund_tx)
        expect(Ai::WalletTransaction.credits).not_to include(deduction_tx)
      end
    end

    describe '.debits' do
      it 'returns deductions' do
        expect(Ai::WalletTransaction.debits).to include(deduction_tx)
        expect(Ai::WalletTransaction.debits).not_to include(topup_tx, refund_tx)
      end
    end
  end
end
