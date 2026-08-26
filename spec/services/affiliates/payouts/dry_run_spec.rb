# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::DryRun do
  let!(:profile1) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:profile2) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:disabled_profile) { create(:affiliate_profile, payouts_enabled: false) }

  describe "#call" do
    it "returns preview hashes for eligible profiles with available commissions" do
      create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)
      create(:affiliate_commission, profile: profile1, status: :available, amount: 30.0)
      create(:affiliate_commission, profile: profile2, status: :available, amount: 100.0)

      result = described_class.call

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)

      p1_result = result.find { |r| r[:profile_id] == profile1.id }
      p2_result = result.find { |r| r[:profile_id] == profile2.id }

      expect(p1_result[:amount]).to eq(80.0)
      expect(p1_result[:commission_count]).to eq(2)
      expect(p1_result[:referral_code]).to eq(profile1.referral_code)

      expect(p2_result[:amount]).to eq(100.0)
      expect(p2_result[:commission_count]).to eq(1)
    end

    it "does NOT create any Payout or PayoutBatch records" do
      create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)

      expect { described_class.call }.not_to change(Affiliate::Payout, :count)
      expect { described_class.call }.not_to change(Affiliate::PayoutBatch, :count)
    end

    it "does NOT mark commissions as paid" do
      commission = create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)

      described_class.call

      expect(commission.reload.status).to eq("available")
    end

    it "filters by profile_ids when provided" do
      create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)
      create(:affiliate_commission, profile: profile2, status: :available, amount: 100.0)

      result = described_class.call(profile_ids: [profile1.id])

      expect(result.size).to eq(1)
      expect(result.first[:profile_id]).to eq(profile1.id)
    end

    it "excludes profiles with no available commissions" do
      create(:affiliate_commission, profile: profile1, status: :paid, amount: 50.0)
      create(:affiliate_commission, profile: profile2, status: :available, amount: 100.0)

      result = described_class.call

      expect(result.size).to eq(1)
      expect(result.first[:profile_id]).to eq(profile2.id)
    end

    it "excludes disabled profiles" do
      create(:affiliate_commission, profile: disabled_profile, status: :available, amount: 50.0)

      result = described_class.call

      expect(result).to be_empty
    end

    it "returns empty array when no eligible profiles exist" do
      Affiliate::Profile.update_all(payouts_enabled: false)

      expect(described_class.call).to eq([])
    end

    it "includes valid_bank_details status in preview" do
      create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)
      allow_any_instance_of(Affiliate::Profile).to receive(:valid_bank_details?).and_return(true)

      result = described_class.call(profile_ids: [profile1.id])

      expect(result.first[:valid_bank_details]).to be(true)
    end

    it "rescues and logs errors for individual profiles" do
      create(:affiliate_commission, profile: profile1, status: :available, amount: 50.0)

      allow_any_instance_of(Affiliate::Profile).to receive(:valid_bank_details?).and_raise(StandardError.new("boom"))

      expect(Rails.logger).to receive(:error).with(/DryRun calculation failed/).at_least(:once)

      result = described_class.call
      expect(result).to eq([])
    end
  end
end
