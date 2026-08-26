# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::InvoiceWorker, type: :worker do
  let(:user) { create(:user, email: "affiliate@example.com") }
  let(:profile) { create(:affiliate_profile, user: user) }
  let(:payout) { create(:affiliate_payout, profile: profile, status: :paid) }
  let(:worker) { described_class.new }

  describe "#perform" do
    it "generates invoice PDF and delivers the email" do
      expect(Affiliates::Payouts::InvoiceGenerator).to receive(:call).with(payout: payout).and_call_original

      expect {
        worker.perform(payout.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      delivery = ActionMailer::Base.deliveries.last
      expect(delivery.to).to eq(["affiliate@example.com"])
      expect(delivery.attachments.size).to eq(1)
    end

    it "skips processing if payout is not in paid status" do
      payout.update!(status: :processing)

      expect(Affiliates::Payouts::InvoiceGenerator).not_to receive(:call)
      expect {
        worker.perform(payout.id)
      }.not_to change { ActionMailer::Base.deliveries.count }
    end

    it "returns silently if payout is not found" do
      expect {
        worker.perform(SecureRandom.uuid)
      }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
