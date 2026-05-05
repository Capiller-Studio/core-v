require 'rails_helper'

RSpec.describe Subscription, type: :model do
  subject { build(:subscription) }

  describe 'Associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:plan) }
    it { is_expected.to have_many(:transactions).dependent(:nullify) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, trialing: 1, past_due: 2, cancelled: 3, expired: 4) }
    it { is_expected.to define_enum_for(:billing_cycle).with_values(monthly: 0, annual: 1) }
    it { is_expected.to define_enum_for(:provider).with_values(stripe: 0, paddle: 1) }
  end

  describe 'Validations' do
    it 'validates uniqueness of account_id scoped to status active/trialing' do
      account = create(:account)
      create(:subscription, account: account, status: :active)

      duplicate = build(:subscription, account: account, status: :trialing)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:account_id]).to include("already has an active subscription")
    end
  end

  describe '#trialing?' do
    it 'returns true if status is trialing and end date is in future' do
      sub = build(:subscription, status: :trialing, trial_end_at: 1.day.from_now)
      expect(sub.trialing?).to be true
    end

    it 'returns false if trial ended' do
      sub = build(:subscription, status: :trialing, trial_end_at: 1.day.ago)
      expect(sub.trialing?).to be false
    end
  end

  describe '#total_price' do
    let(:plan) { create(:plan) }
    let(:account) { create(:account) }
    let(:subscription) { create(:subscription, account: account, plan: plan, billing_cycle: :monthly) }

    it 'calculates total based on billable agents' do
      # Assuming plan price is 29.0 for monthly (from Account model spec or plan logic)
      allow(plan).to receive(:price_for).with('monthly').and_return(30.0)
      allow(account).to receive(:users_count).and_return(5)

      expect(subscription.total_price).to eq(150.0)
    end
  end
end
