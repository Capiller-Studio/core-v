require 'rails_helper'

RSpec.describe Wallet, type: :model do
  subject { build(:wallet) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe '#credit!' do
    it 'increments balance and records transaction' do
      wallet = create(:wallet, balance: 100)
      expect {
        wallet.credit!(50, description: 'Topup')
      }.to change { wallet.balance }.from(100).to(150)
      
      expect(wallet.wallet_transactions.count).to eq(1)
      expect(wallet.wallet_transactions.last.amount).to eq(50)
    end
  end

  describe '#deduct!' do
    it 'decrements balance if sufficient and records transaction' do
      wallet = create(:wallet, balance: 100)
      expect {
        wallet.deduct!(40, description: 'Service charge')
      }.to change { wallet.balance }.from(100).to(60)
    end

    it 'raises InsufficientBalanceError if balance is too low' do
      wallet = create(:wallet, balance: 30)
      expect {
        wallet.deduct!(40)
      }.to raise_error(InsufficientBalanceError)
    end
  end

  describe '#sufficient_balance?' do
    it 'returns true if balance >= amount' do
      wallet = build(:wallet, balance: 50)
      expect(wallet.sufficient_balance?(40)).to be true
      expect(wallet.sufficient_balance?(50)).to be true
      expect(wallet.sufficient_balance?(60)).to be false
    end
  end
end
