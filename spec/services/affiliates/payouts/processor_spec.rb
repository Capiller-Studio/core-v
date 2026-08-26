# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::Processor do
  let(:profile) { double("Affiliate::Profile", id: "prof_1") }
  let(:commissions) { double("Commissions") }
  let(:commissions_where) { double("CommissionsWhere") }
  let(:payout) do
    double(
      "Affiliate::Payout",
      id: "pay_1",
      affiliate_profile_id: "prof_1",
      profile: profile,
      commission_ids: %w[c1 c2],
      paid?: false
    )
  end
  let(:service) { described_class.new(payout: payout) }

  describe "#call" do
    before do
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
      allow(profile).to receive(:commissions).and_return(commissions)
      allow(commissions).to receive(:where).with(id: %w[c1 c2]).and_return(commissions_where)
    end

    it "returns nil if already paid" do
      allow(payout).to receive(:paid?).and_return(true)
      expect(service.call).to be_nil
    end

    it "acquires a mutex lock on PAYOUT_LOCK" do
      expected_lock = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: "prof_1")
      expect(::RedisUtilities::MutexHelpers).to receive(:with_lock).with(expected_lock).and_yield
      allow(payout).to receive(:provider).and_return("manual")
      allow(payout).to receive(:update!).with(status: :paid)

      service.call
    end

    context "when provider is manual" do
      before do
        allow(payout).to receive(:provider).and_return("manual")
      end

      it "updates payout status to paid" do
        expect(payout).to receive(:update!).with(status: :paid)
        service.call
      end
    end

    context "when provider is wise" do
      before do
        allow(payout).to receive(:provider).and_return("wise")
      end

      it "updates status to processing and queues TransferWorker" do
        expect(payout).to receive(:update!).with(status: :processing)
        expect(Affiliates::Wise::TransferWorker).to receive(:perform_async).with("pay_1")

        service.call
      end
    end

    context "on error" do
      before do
        allow(payout).to receive(:provider).and_return("manual")
      end

      it "marks payout as failed, restores associated commissions to available status, and returns nil" do
        allow(payout).to receive(:update!).with(status: :paid).and_raise(StandardError.new("Network Error"))
        expect(payout).to receive(:update!).with(status: :failed)
        expect(commissions_where).to receive(:update_all).with(status: :available)

        expect(service.call).to be_nil
      end
    end
  end
end
