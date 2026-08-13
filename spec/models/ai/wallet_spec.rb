require 'rails_helper'

RSpec.describe Ai::Wallet, type: :model do
  # Use build because account factory might create a wallet via callback
  subject(:wallet) { account.ai_wallet || build(:ai_wallet, account: account) }

  let(:account) { create(:account) }


  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:wallet_transactions).class_name('Ai::WalletTransaction').with_foreign_key('ai_wallet_id').dependent(:destroy) }
    it { is_expected.to have_many(:credit_grants).class_name('Ai::CreditGrant').with_foreign_key('ai_wallet_id').dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:balance) }
    it { is_expected.to validate_numericality_of(:balance).only_integer }
    
    it 'validates uniqueness of account_id' do
      wallet.save! if wallet.new_record?
      duplicate_wallet = described_class.new(account: account, balance: 0)
      expect(duplicate_wallet).not_to be_valid
      expect(duplicate_wallet.errors[:account_id]).to include("has already been taken")
    end
  end

  describe '#available_balance' do
    it 'returns the sum of active credit grants' do
      wallet.save! if wallet.new_record?
      
      # Should ignore expired grants
      create(:ai_credit_grant, wallet: wallet, balance: 50, expires_at: 1.day.ago)
      
      # Should sum active grants
      create(:ai_credit_grant, wallet: wallet, balance: 100, expires_at: 1.day.from_now)
      create(:ai_credit_grant, wallet: wallet, balance: 25, expires_at: 1.month.from_now)

      expect(wallet.available_balance).to eq(125)
    end
  end

  describe '#sufficient_balance?' do
    it 'returns true when available balance is greater than or equal to amount' do
      wallet.save! if wallet.new_record?
      create(:ai_credit_grant, wallet: wallet, balance: 100, expires_at: 1.day.from_now)
      
      expect(wallet.sufficient_balance?(50)).to be true
      expect(wallet.sufficient_balance?(100)).to be true
    end

    it 'returns false when available balance is less than amount' do
      wallet.save! if wallet.new_record?
      create(:ai_credit_grant, wallet: wallet, balance: 100, expires_at: 1.day.from_now)
      
      expect(wallet.sufficient_balance?(101)).to be false
    end
  end

  describe '#deduct!' do
    let(:wallet) { account.ai_wallet || create(:ai_wallet, account: account, balance: 100) }

    before do
      create(:ai_credit_grant, wallet: wallet, balance: 60, expires_at: 1.day.from_now)
      create(:ai_credit_grant, wallet: wallet, balance: 40, expires_at: 1.month.from_now)
      wallet.update!(balance: 100)
    end

    it 'raises AiInsufficientBalanceError if balance is insufficient and not forced' do
      expect {
        wallet.deduct!(150, action_type: 'generate_text', model_used: 'gpt-4')
      }.to raise_error(AiInsufficientBalanceError)
    end

    it 'deducts from grants expiring first' do
      wallet.deduct!(80, action_type: 'generate_text', model_used: 'gpt-4')
      
      # The 60 balance grant should be 0, the 40 balance grant should be 20
      grants = wallet.credit_grants.order(expires_at: :asc)
      expect(grants.first.balance).to eq(0)
      expect(grants.last.balance).to eq(20)
      
      expect(wallet.reload.balance).to eq(20)
    end

    it 'creates a wallet transaction record' do
      expect {
        wallet.deduct!(30, action_type: 'generate_text', model_used: 'gpt-4', description: 'Test deduction')
      }.to change(Ai::WalletTransaction, :count).by(1)

      transaction = Ai::WalletTransaction.last
      expect(transaction.amount).to eq(30)
      expect(transaction.transaction_type).to eq('deduction')
      expect(transaction.action_type).to eq('generate_text')
      expect(transaction.model_used).to eq('gpt-4')
      expect(transaction.description).to eq('Test deduction')
    end

    it 'allows overdraft if force is true' do
      wallet.deduct!(150, action_type: 'generate_text', model_used: 'gpt-4', force: true)
      
      grants = wallet.credit_grants.order(expires_at: :asc)
      expect(grants.first.balance).to eq(0)
      expect(grants.last.balance).to eq(0)
      
      expect(wallet.reload.balance).to eq(0)
      
      transaction = Ai::WalletTransaction.last
      expect(transaction.amount).to eq(150)
    end
  end

  describe '#grant_credits!' do
    let(:wallet) { account.ai_wallet || create(:ai_wallet, account: account, balance: 0) }

    it 'creates a credit grant and updates balance' do
      expect {
        wallet.grant_credits!(100, grant_type: :purchased, expires_at: 1.year.from_now, description: 'Test topup')
      }.to change(Ai::CreditGrant, :count).by(1)

      grant = Ai::CreditGrant.last
      expect(grant.amount).to eq(100)
      expect(grant.balance).to eq(100)
      expect(grant.grant_type).to eq('purchased')
      
      expect(wallet.reload.balance).to eq(100)
    end

    it 'creates a wallet transaction record' do
      expect {
        wallet.grant_credits!(50, grant_type: :purchased, expires_at: 1.year.from_now)
      }.to change(Ai::WalletTransaction, :count).by(1)

      transaction = Ai::WalletTransaction.last
      expect(transaction.amount).to eq(50)
      expect(transaction.transaction_type).to eq('topup')
    end
  end

  describe '#refund!' do
    let(:wallet) { account.ai_wallet || create(:ai_wallet, account: account, balance: 0) }

    it 'creates a refund credit grant and updates balance' do
      expect {
        wallet.refund!(25, description: 'Failed API call refund')
      }.to change(Ai::CreditGrant, :count).by(1)

      grant = Ai::CreditGrant.last
      expect(grant.amount).to eq(25)
      expect(grant.grant_type).to eq('refund')
      
      expect(wallet.reload.balance).to eq(25)
    end

    it 'creates a refund wallet transaction record' do
      expect {
        wallet.refund!(25)
      }.to change(Ai::WalletTransaction, :count).by(1)

      transaction = Ai::WalletTransaction.last
      expect(transaction.amount).to eq(25)
      expect(transaction.transaction_type).to eq('refund')
    end
  end
end
