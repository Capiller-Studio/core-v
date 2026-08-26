# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::BatchGeneratorWorker do
  let(:worker) { described_class.new }
  let!(:profile1) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:profile2) { create(:affiliate_profile, payouts_enabled: true) }
  let!(:disabled_profile) { create(:affiliate_profile, payouts_enabled: false) }

  before do
    allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
    allow(Affiliates::BankDetailsValidator).to receive(:call).and_return(double(success?: true))
  end

  describe "#perform" do
    it "acquires a distributed lock on PAYOUT_GENERATION_LOCK" do
      expect(::RedisUtilities::MutexHelpers).to receive(:with_lock)
        .with(::RedisUtilities::Keys::PAYOUT_GENERATION_LOCK)
        .and_yield

      worker.perform
    end

    it "handles MutexLockError gracefully without raising" do
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock)
        .and_raise(MutexLockError.new("Resource locked"))

      expect(Rails.logger).to receive(:warn).with(/Payout Batch Generation skipped/)
      expect { worker.perform }.not_to raise_error
    end

    context "when running in grouped batch mode (batch_payout = true)" do
      context "with manual provider" do
        it "creates a payout batch, generates payouts, and marks them funded and paid" do
          create(:affiliate_commission, profile: profile1, status: :available, amount: 100.0)
          create(:affiliate_commission, profile: profile2, status: :available, amount: 200.0)

          expect {
            worker.perform(nil, true, "manual")
          }.to change(Affiliate::PayoutBatch, :count).by(1)
           .and change(Affiliate::Payout, :count).by(2)

          batch = Affiliate::PayoutBatch.last
          expect(batch.status).to eq("funded")
          expect(batch.provider).to eq("manual")
          expect(batch.total_amount).to eq(300.0)
          expect(batch.payouts.pluck(:status).uniq).to eq(["paid"])
        end

        it "destroys the batch if no eligible payouts were generated" do
          expect {
            worker.perform(nil, true, "manual")
          }.not_to change(Affiliate::PayoutBatch, :count)
        end
      end

      context "with wise provider" do
        it "creates a payout batch, sets status to processing, and enqueues BatchGroupCreatorWorker" do
          create(:affiliate_commission, profile: profile1, status: :available, amount: 150.0)

          expect(Affiliates::Wise::BatchGroupCreatorWorker).to receive(:perform_async).with(anything)

          expect {
            worker.perform([profile1.id], true, "wise")
          }.to change(Affiliate::PayoutBatch, :count).by(1)
           .and change(Affiliate::Payout, :count).by(1)

          batch = Affiliate::PayoutBatch.last
          expect(batch.status).to eq("processing")
          expect(batch.provider).to eq("wise")
          expect(batch.total_amount).to eq(150.0)
        end
      end
    end

    context "when running in standalone individual mode (batch_payout = false)" do
      it "generates standalone payouts without creating a PayoutBatch" do
        create(:affiliate_commission, profile: profile1, status: :available, amount: 75.0)

        expect {
          expect {
            worker.perform([profile1.id], false, "manual")
          }.to change(Affiliate::Payout, :count).by(1)
        }.not_to change(Affiliate::PayoutBatch, :count)

        payout = Affiliate::Payout.last
        expect(payout.payout_batch_id).to be_nil
        expect(payout.status).to eq("paid")
        expect(payout.amount).to eq(75.0)
      end
    end
  end
end
