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

  describe '.due_for_renewal' do
    let(:account) { create(:account) }

    it 'includes active subscriptions past current_period_end that are not cancelled' do
      sub = create(:subscription, account: account, status: :active, current_period_end: 1.hour.ago, cancelled_at: nil)
      expect(described_class.due_for_renewal).to include(sub)
    end

    it 'excludes active subscriptions scheduled for cancellation' do
      sub = create(:subscription, account: account, status: :active, current_period_end: 1.hour.ago, cancelled_at: 1.day.ago)
      expect(described_class.due_for_renewal).not_to include(sub)
    end

    it 'excludes subscriptions whose current_period_end is in the future' do
      sub = create(:subscription, account: account, status: :active, current_period_end: 1.day.from_now)
      expect(described_class.due_for_renewal).not_to include(sub)
    end
  end

  describe '#due_for_renewal?' do
    it 'returns true for active subscription past period end with no cancelled_at' do
      sub = build(:subscription, status: :active, current_period_end: 1.hour.ago, cancelled_at: nil)
      expect(sub.due_for_renewal?).to be true
    end

    it 'returns false for active subscription with cancelled_at' do
      sub = build(:subscription, status: :active, current_period_end: 1.hour.ago, cancelled_at: 1.hour.ago)
      expect(sub.due_for_renewal?).to be false
    end
  end

  describe '#total_price' do
    let(:plan) { create(:plan) }
    let(:account) { create(:account) }
    let(:subscription) { create(:subscription, account: account, plan: plan, billing_cycle: :monthly, quantity: 5) }

    it 'calculates total based on billable agents' do
      allow(plan).to receive(:base_price).and_return(30.0)
      allow(account).to receive(:users_count).and_return(5)

      expect(subscription.total_price).to eq(150.0)
    end
  end
end
