# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Affiliate::Referral, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user) }
  let(:profile) { create(:affiliate_profile, user: user) }
  let(:referral) { create(:affiliate_referral, profile: profile, account: account) }

  describe 'associations and enums' do
    it { is_expected.to belong_to(:profile).class_name('Affiliate::Profile').with_foreign_key('affiliate_profile_id').inverse_of(:referrals) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:commissions).class_name('Affiliate::Commission').with_foreign_key('affiliate_referral_id').dependent(:destroy).inverse_of(:referral) }
    it { is_expected.to define_enum_for(:status).with_values(active: 0, expired: 1) }
  end

  describe '#remaining_tenure_months' do
    it 'calculates tenure months remaining' do
      expect(referral.remaining_tenure_months).to be >= 0
    end
  end

  describe '#total_revenue and #total_commission' do
    let(:plan) { create(:plan, name: Plan::PARABOLIC) }
    let(:subscription) { create(:subscription, account: account, plan: plan) }
    let(:transaction) { create(:transaction, account: account, subscription: subscription) }

    it 'calculates sums from associated commissions' do
      create(:affiliate_commission, referral: referral, profile: profile, transaction_record: transaction, amount: 25.0)
      create(:affiliate_commission, referral: referral, profile: profile, transaction_record: transaction, amount: 35.0)

      expect(referral.total_commission).to eq(referral.commissions.sum(:amount))
    end
  end
end
