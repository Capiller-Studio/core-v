require "rails_helper"

RSpec.describe Webhook::Incoming, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:payload) }
  end

  describe "Enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processed: 1, failed: 2, permanently_failed: 3) }
  end

  describe "#route_params" do
    subject(:webhook) { build(:webhook_incoming, request_url: request_url) }

    context "when the router recognises the URL path" do
      let(:request_url) { "https://deskbolic.app/webhooks/custom/123/456" }

      before do
        allow(Rails.application.routes).to receive(:recognize_path)
          .with("/webhooks/custom/123/456", method: :post)
          .and_return({ controller: "webhooks/custom", action: "create", account_id: "123", channel_id: "456" })
      end

      it "returns the named route parameters" do
        params = webhook.route_params
        expect(params[:account_id]).to eq("123")
        expect(params[:channel_id]).to eq("456")
      end
    end

    context "when request_url is blank" do
      let(:request_url) { nil }

      it { expect(webhook.route_params).to eq({}) }
    end

    context "when the path does not match any route" do
      let(:request_url) { "https://deskbolic.app/unknown/path" }

      before do
        allow(Rails.application.routes).to receive(:recognize_path)
          .and_raise(ActionController::RoutingError.new("No route matches"))
      end

      it { expect(webhook.route_params).to eq({}) }
    end
  end

  describe "#query_params" do
    subject(:webhook) { build(:webhook_incoming, request_url: request_url) }

    context "when request_url has a query string" do
      let(:request_url) { "https://deskbolic.app/webhooks/whatsapp?channel_id=99&account_id=1" }

      it "extracts query parameters" do
        params = webhook.query_params
        expect(params["channel_id"]).to eq("99")
        expect(params["account_id"]).to eq("1")
      end
    end

    context "when request_url has no query string" do
      let(:request_url) { "https://deskbolic.app/webhooks/stripe" }

      it { expect(webhook.query_params).to eq({}) }
    end

    context "when request_url is blank" do
      let(:request_url) { nil }

      it { expect(webhook.query_params).to eq({}) }
    end
  end

  describe "event_type" do
    it "is optional (nullable)" do
      webhook = build(:webhook_incoming, event_type: nil)
      expect(webhook).to be_valid
    end

    it "stores the event type correctly" do
      webhook = create(:webhook_incoming, event_type: "charge.refunded")
      expect(webhook.reload.event_type).to eq("charge.refunded")
    end
  end
end
