# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliates::Payouts::InvoiceGenerator do
  let(:user) { create(:user, email: "affiliate@example.com", name: "Jane Doe") }
  let(:profile) { create(:affiliate_profile, user: user, referral_code: "JANEDOE8") }
  let(:payout) { create(:affiliate_payout, profile: profile, amount: 250.0, currency: "USD", status: :paid) }
  let(:service) { described_class.new(payout: payout) }

  describe "#call" do
    it "returns false if payout is nil" do
      expect(described_class.new(payout: nil).call).to be(false)
    end

    it "generates a valid PDF document and attaches it to payout.invoice_pdf" do
      expect(payout.invoice_pdf).not_to be_attached

      result = service.call

      expect(payout.reload.invoice_pdf).to be_attached
      expect(payout.invoice_pdf.filename.to_s).to eq("payout-statement-#{payout.code}.pdf")
      expect(payout.invoice_pdf.content_type).to eq("application/pdf")
      expect(payout.invoice_pdf.byte_size).to be > 1000
    end

    it "includes associated commission line items when present" do
      c1 = create(:affiliate_commission, profile: profile, amount: 150.0, status: :paid)
      c2 = create(:affiliate_commission, profile: profile, amount: 100.0, status: :paid)
      payout.update!(commission_ids: [c1.id, c2.id])

      expect { service.call }.not_to raise_error
      expect(payout.reload.invoice_pdf).to be_attached
    end
  end
end
