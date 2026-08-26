# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::Wise::BatchFunder do
  let(:payouts) { double("PayoutsAssociation", update_all: true, find_each: []) }
  let(:payout_batch) do
    double(
      "Affiliate::PayoutBatch",
      id: "batch_1",
      external_id: "bg-123",
      funded?: false,
      data: {},
      payouts: payouts,
      reload: true
    )
  end
  let(:service) { described_class.new(payout_batch: payout_batch) }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_endpoint).and_return("https://api.transferwise.com")
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :profile_id).and_return("prof-123")
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_key).and_return("secret-key")
    allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe "#call" do
    context "when already funded or no external_id" do
      it "returns false if funded" do
        allow(payout_batch).to receive(:funded?).and_return(true)
        expect(service.call).to be(false)
      end

      it "returns false if external_id is blank" do
        allow(payout_batch).to receive(:external_id).and_return(nil)
        expect(service.call).to be(false)
      end
    end

    context "when funding successfully" do
      let(:http_response) { double("HTTPResponse", success?: true, body: '{"success": true}', headers: {}) }

      before do
        allow(HTTParty).to receive(:post).and_return(http_response)
        allow(payout_batch).to receive(:update!)
      end

      it "acquires mutex lock, calls API, and marks batch funded and payouts paid" do
        expected_lock = format(::RedisUtilities::Keys::PAYOUT_BATCH_LOCK, batch_id: "batch_1")
        expect(::RedisUtilities::MutexHelpers).to receive(:with_lock).with(expected_lock).and_yield

        expect(HTTParty).to receive(:post).with(
          "https://api.transferwise.com/v3/profiles/prof-123/batch-groups/bg-123/payments",
          headers: {
            "Authorization" => "Bearer secret-key",
            "Content-Type" => "application/json"
          },
          body: { "type" => "BALANCE" }.to_json
        )

        expect(payout_batch).to receive(:update!).with(data: { "api_responses" => { "fund_0" => { "success" => true } } })
        expect(payout_batch).to receive(:update!).with(status: :funded, funded_at: anything)
        expect(payouts).to receive(:update_all).with(status: :paid)

        expect(service.call).to be(true)
      end
    end

    context "when 2FA is required" do
      let(:rejected_response) { double("HTTPResponse", success?: false, body: '{"error":"2fa"}', headers: { "x-2fa-approval-result" => "REJECTED", "x-2fa-approval" => "token123" }) }
      let(:success_response) { double("HTTPResponse", success?: true, body: '{"success":true}', headers: {}) }

      before do
        allow(payout_batch).to receive(:update!)
        allow(Affiliates::Payouts::Wise::Signer).to receive(:call).with("token123").and_return("sig123")
      end

      it "retries with signed token" do
        # First call fails with 2FA requirement
        expect(HTTParty).to receive(:post).with(
          anything,
          hash_including(headers: hash_not_including("x-2fa-approval" => "token123"))
        ).and_return(rejected_response)

        # Second call succeeds
        expect(HTTParty).to receive(:post).with(
          anything,
          hash_including(headers: hash_including("x-2fa-approval" => "token123", "X-Signature" => "sig123"))
        ).and_return(success_response)

        expect(service.call).to be(true)
      end
    end

    context "when an error occurs" do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new("Net error"))
        allow(payout_batch).to receive(:update!)
      end

      it "rescues and returns false" do
        expect(Rails.logger).to receive(:error).with(/Wise Batch Funder Exception/)
        expect(service.call).to be(false)
      end
    end
  end
end
