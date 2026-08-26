# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::Wise::TransferCreator do
  let(:profile) do
    double(
      "Affiliate::Profile",
      id: "prof_1",
      payment_details: { "account_holder_name" => "John Doe", "legal_type" => "PRIVATE" },
      wise_bank_details_payload: { type: "aba", details: { "routingNumber" => "123", "accountNumber" => "456" } }
    )
  end
  let(:payout_batch) { nil }
  let(:payout) do
    double(
      "Affiliate::Payout",
      id: "pay_1",
      code: "AFF001",
      affiliate_profile_id: "prof_1",
      external_id: nil,
      currency: "USD",
      amount: 100.0,
      profile: profile,
      payout_batch_id: payout_batch ? "batch_1" : nil,
      payout_batch: payout_batch,
      data: {},
      reload: true
    )
  end
  let(:service) { described_class.new(payout: payout) }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_endpoint).and_return("https://api.transferwise.com")
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :profile_id).and_return("prof-123")
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_key).and_return("secret-key")
    allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe "#call" do
    context "when external_id already exists" do
      before do
        allow(payout).to receive(:external_id).and_return("tr-123")
      end

      it "returns early without making API calls" do
        expect(HTTParty).not_to receive(:post)
        expect(service.call).to eq("tr-123")
      end
    end

    context "when bank details are invalid" do
      before do
        stub_const("Affiliates::BankDetailsValidator", double("Validator"))
        allow(Affiliates::BankDetailsValidator).to receive(:call).with(profile).and_return(double(success?: false, error: "Invalid ABA"))
        allow(payout).to receive(:update!)
      end

      it "fails the payout and logs reason" do
        expect(payout).to receive(:update!).with(status: :failed)
        expect(payout).to receive(:update!).with(data: { "error" => "Invalid ABA" })
        expect(service.call).to be_nil
      end
    end

    context "when bank details are valid" do
      before do
        stub_const("Affiliates::BankDetailsValidator", double("Validator"))
        allow(Affiliates::BankDetailsValidator).to receive(:call).with(profile).and_return(double(success?: true))
        allow(payout).to receive(:update!)
      end

      context "and API calls succeed for standalone transfer" do
        let(:quote_response) { double("HTTPResponse", success?: true, body: '{"id":"quote-123"}') }
        let(:account_response) { double("HTTPResponse", success?: true, body: '{"id":"account-456"}') }
        let(:transfer_response) { double("HTTPResponse", success?: true, body: '{"id":"transfer-789"}') }

        it "acquires mutex lock, creates quote, account, and transfer" do
          expected_lock = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: "prof_1")
          expect(::RedisUtilities::MutexHelpers).to receive(:with_lock).with(expected_lock).and_yield

          expect(HTTParty).to receive(:post).with(
            "https://api.transferwise.com/v2/quotes",
            anything
          ).ordered.and_return(quote_response)

          expect(HTTParty).to receive(:post).with(
            "https://api.transferwise.com/v1/accounts",
            anything
          ).ordered.and_return(account_response)

          expect(HTTParty).to receive(:post).with(
            "https://api.transferwise.com/v1/transfers",
            hash_including(body: /"targetAccount":"account-456"/)
          ).ordered.and_return(transfer_response)

          allow(payout).to receive(:update!)
          expect(payout).to receive(:update!).with(external_id: "transfer-789")
          expect(service.call).to eq("transfer-789")
        end
      end

      context "and API calls succeed for batch transfer" do
        let(:payout_batch) { double("Affiliate::PayoutBatch", external_id: "batch-bg-1") }

        let(:quote_response) { double("HTTPResponse", success?: true, body: '{"id":"quote-123"}') }
        let(:account_response) { double("HTTPResponse", success?: true, body: '{"id":"account-456"}') }
        let(:transfer_response) { double("HTTPResponse", success?: true, body: '{"id":"transfer-789"}') }

        it "creates a batch transfer with batch-group endpoint" do
          expect(HTTParty).to receive(:post).with("https://api.transferwise.com/v2/quotes", anything).ordered.and_return(quote_response)
          expect(HTTParty).to receive(:post).with("https://api.transferwise.com/v1/accounts", anything).ordered.and_return(account_response)

          expect(HTTParty).to receive(:post).with(
            "https://api.transferwise.com/v3/profiles/prof-123/batch-groups/batch-bg-1/transfers",
            hash_including(body: /"targetAccount":"account-456"/)
          ).ordered.and_return(transfer_response)

          allow(payout).to receive(:update!)
          expect(payout).to receive(:update!).with(external_id: "transfer-789")
          expect(service.call).to eq("transfer-789")
        end
      end
    end
  end
end
