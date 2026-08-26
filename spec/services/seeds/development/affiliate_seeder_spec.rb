# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seeds::Development::AffiliateSeeder do
  describe ".seed" do
    it "seeds affiliates, referrals, commissions, and payout batches successfully" do
      expect { described_class.seed }.not_to raise_error

      expect(Affiliate::Profile.count).to be >= 5
      expect(Affiliate::Referral.count).to be >= 5
      expect(Affiliate::Commission.count).to be >= 8
      expect(Affiliate::PayoutBatch.count).to be >= 1
      expect(Affiliate::Payout.count).to be >= 2

      # Verify individual profiles
      sophia = Affiliate::Profile.joins(:user).find_by(users: { email: "sophia.turner@deskbolic.test" })
      expect(sophia).to be_present
      expect(sophia.payouts_enabled).to be(true)
      expect(sophia.currency).to eq("USD")
      expect(sophia.commissions.where(status: :available).count).to be >= 3

      david = Affiliate::Profile.joins(:user).find_by(users: { email: "david.kim@deskbolic.test" })
      expect(david).to be_present
      expect(david.payouts_enabled).to be(false)

      oliver = Affiliate::Profile.joins(:user).find_by(users: { email: "oliver.smith@deskbolic.test" })
      expect(oliver).to be_present
      expect(oliver.currency).to eq("GBP")
    end

    it "is idempotent and can be run multiple times without duplication" do
      described_class.seed
      initial_profile_count = Affiliate::Profile.count
      initial_batch_count = Affiliate::PayoutBatch.count

      described_class.seed

      expect(Affiliate::Profile.count).to eq(initial_profile_count)
      expect(Affiliate::PayoutBatch.count).to eq(initial_batch_count)
    end
  end
end
