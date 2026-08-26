# frozen_string_literal: true

class AffiliatePayoutMailer < ApplicationMailer
  def invoice(payout_id)
    @payout = Affiliate::Payout.find_by(id: payout_id)
    return unless @payout

    @profile = @payout.profile
    @user = @profile&.user
    return unless @user&.email.present?

    unless @payout.invoice_pdf.attached?
      Affiliates::Payouts::InvoiceGenerator.call(payout: @payout)
      @payout.reload
    end

    if @payout.invoice_pdf.attached?
      attachments["payout-statement-#{@payout.code}.pdf"] = @payout.invoice_pdf.download
    end

    mail(
      to: @user.email,
      subject: "Your Affiliate Payout Statement - #{@payout.code}"
    )
  end
end
