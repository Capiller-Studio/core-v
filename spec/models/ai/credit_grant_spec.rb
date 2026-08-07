require 'rails_helper'

RSpec.describe Ai::CreditGrant, type: :model do
  subject { build(:ai_credit_grant) }

  describe 'Associations' do
    it { is_expected.to belong_to(:wallet).class_name("Ai::Wallet").with_foreign_key("ai_wallet_id") }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:grant_type).with_values(monthly_free: 0, purchased: 1, promotion: 2, refund: 3) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_numericality_of(:amount).only_integer.is_greater_than(0) }
    
    it { is_expected.to validate_presence_of(:balance) }
    it { is_expected.to validate_numericality_of(:balance).only_integer.is_greater_than_or_equal_to(0) }
    
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe 'Scopes and Methods' do
    let(:account) { create(:account) }
    let(:wallet) { account.ai_wallet }
    
    let!(:active_grant) { create(:ai_credit_grant, wallet: wallet, balance: 100, expires_at: 1.day.from_now) }
    let!(:exhausted_grant) { create(:ai_credit_grant, wallet: wallet, balance: 0, expires_at: 1.day.from_now) }
    let!(:expired_grant) { create(:ai_credit_grant, wallet: wallet, balance: 100, expires_at: 1.day.ago) }

    describe '.active' do
      it 'returns grants with balance > 0 and future expiration' do
        expect(Ai::CreditGrant.active).to include(active_grant)
        expect(Ai::CreditGrant.active).not_to include(exhausted_grant, expired_grant)
      end
    end

    describe '#active?' do
      it { expect(active_grant.active?).to be true }
      it { expect(exhausted_grant.active?).to be false }
      it { expect(expired_grant.active?).to be false }
    end

    describe '#expired?' do
      it { expect(active_grant.expired?).to be false }
      it { expect(expired_grant.expired?).to be true }
    end

    describe '#exhausted?' do
      it { expect(active_grant.exhausted?).to be false }
      it { expect(exhausted_grant.exhausted?).to be true }
    end
  end
end
