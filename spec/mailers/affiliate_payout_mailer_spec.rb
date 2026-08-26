# frozen_string_literal: true

require "rails_helper"

RSpec.describe AffiliatePayoutMailer, type: :mailer do
  let(:user) { create(:user, email: "affiliate@example.com", name: "Jane Doe") }
  let(:profile) { create(:affiliate_profile, user: user) }
  let(:payout) { create(:affiliate_payout, profile: profile, amount: 250.0, currency: "USD", status: :paid) }

  describe "#invoice" do
    it "renders the email with the attached payout PDF" do
      mail = described_class.invoice(payout.id)

      expect(mail.to).to eq(["affiliate@example.com"])
      expect(mail.subject).to eq("Your Affiliate Payout Statement - #{payout.code}")
      expect(mail.attachments.size).to eq(1)
      expect(mail.attachments.first.filename).to eq("payout-statement-#{payout.code}.pdf")
      expect(mail.attachments.first.content_type).to start_with("application/pdf")
      expect(mail.body.encoded).to include(payout.code)
      expect(mail.body.encoded).to include("250.00")
    end

    it "returns nil if payout does not exist" do
      expect(described_class.invoice(SecureRandom.uuid).deliver_now).to be_nil
    end
  end
end
