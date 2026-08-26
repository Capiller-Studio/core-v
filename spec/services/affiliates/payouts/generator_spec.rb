# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::Generator do
  let(:profile) { double("Affiliate::Profile", id: "prof_1", currency: "USD") }
  let(:service) { described_class.new(profile: profile) }

  describe "#call" do
    before do
      allow(profile).to receive(:payouts_enabled?).and_return(true)
      allow(profile).to receive(:valid_bank_details?).and_return(true)
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
    end

    context "when profile is nil" do
      it "returns nil gracefully" do
        expect(described_class.new(profile: nil).call).to be_nil
      end
    end

    context "when validations fail" do
      it "returns nil and logs error if payouts disabled" do
        allow(profile).to receive(:payouts_enabled?).and_return(false)
        expect(Rails.logger).to receive(:error).with(/Payouts disabled/)
        expect(service.call).to be_nil
      end

      it "returns nil and logs error if bank details invalid" do
        allow(profile).to receive(:valid_bank_details?).and_return(false)
        expect(Rails.logger).to receive(:error).with(/Invalid Bank Details/)
        expect(service.call).to be_nil
      end
    end

    context "when processing payouts" do
      let(:commissions) { double("Commissions") }
      let(:c1) { double("Commission", id: "c1", amount: 100.0) }
      let(:c2) { double("Commission", id: "c2", amount: 50.0) }
      let(:locked_commissions) { double("LockedCommissions", to_a: [c1, c2]) }
      let(:payouts) { double("Payouts") }
      let(:payout) { double("Payout", id: "pay_1") }
      let(:commissions_where) { double("CommissionsWhere") }

      before do
        allow(profile).to receive(:commissions).and_return(commissions)
        allow(commissions).to receive(:available).and_return(commissions)
        allow(commissions).to receive(:lock).with("FOR UPDATE").and_return(locked_commissions)
        allow(profile).to receive(:payouts).and_return(payouts)
      end

      it "acquires a Redis lock for the specific profile" do
        expected_lock = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: profile.id)
        expect(::RedisUtilities::MutexHelpers).to receive(:with_lock).with(expected_lock).and_yield
        allow(locked_commissions).to receive(:to_a).and_return([])

        service.call
      end

      it "returns nil if no available commissions exist" do
        allow(locked_commissions).to receive(:to_a).and_return([])
        expect(service.call).to be_nil
      end

      it "returns nil if total payout amount is zero or negative (refund balance)" do
        neg_c = double("Commission", id: "c_neg", amount: -25.0)
        allow(locked_commissions).to receive(:to_a).and_return([neg_c])
        expect(service.call).to be_nil
      end

      it "creates payout and marks claimed commissions as paid atomically" do
        expect(payouts).to receive(:create!).with(
          amount: 150.0,
          currency: "USD",
          status: :processing,
          commission_ids: %w[c1 c2]
        ).and_return(payout)

        expect(commissions).to receive(:where).with(id: %w[c1 c2]).and_return(commissions_where)
        expect(commissions_where).to receive(:update_all).with(status: :paid)

        result = service.call
        expect(result).to eq(payout)
      end

      it "handles unexpected exceptions, logs the error, and returns nil" do
        allow(locked_commissions).to receive(:to_a).and_raise(ActiveRecord::StatementInvalid.new("DB error"))
        expect(Rails.logger).to receive(:error).with(/Payout Manual Generation Failed/)
        expect(service.call).to be_nil
      end
    end
  end
end
