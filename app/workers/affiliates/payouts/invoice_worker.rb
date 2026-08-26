# frozen_string_literal: true

module Affiliates
  module Payouts
    class InvoiceWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 3

      def perform(payout_id)
        payout = Affiliate::Payout.find_by(id: payout_id)
        return unless payout
        return unless payout.paid?

        unless payout.invoice_pdf.attached?
          Affiliates::Payouts::InvoiceGenerator.call(payout: payout)
          payout.reload
        end

        AffiliatePayoutMailer.invoice(payout.id).deliver_now
      rescue StandardError => e
        Rails.logger.error("InvoiceWorker failed for Payout #{payout_id}: #{e.message}")
        raise e
      end
    end
  end
end
