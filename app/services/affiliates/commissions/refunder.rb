# frozen_string_literal: true

module Affiliates
  module Commissions
    class Refunder < ApplicationService
      attr_reader :transaction

      def initialize(transaction:)
        @transaction = transaction
      end

      def call
        # A charge transaction was physically refunded or cancelled. Let's find its attached commission ledger.
        commission = ::Affiliate::Commission.find_by(transaction_record_id: transaction.id)
        return unless commission

        ActiveRecord::Base.transaction do
          if commission.pending? || commission.available?
            # It hasn't been paid out yet. Simply void it completely preventing payout execution identically.
            commission.voided!
          elsif commission.paid?
            # It was already paid out previously. Issue a severe negative commission ledger entry.
            # This mathematically absorbs their next physical earnings preventing revenue bleeding natively.
            ::Affiliate::Commission.create!(
              profile_id: commission.affiliate_profile_id,
              referral_id: commission.affiliate_referral_id,
              transaction_record_id: commission.transaction_record_id,
              original_commission_id: commission.id,
              commission_type: :refund,
              original_amount: -commission.original_amount,
              original_currency: commission.original_currency,
              exchange_rate: commission.exchange_rate,
              amount: -commission.amount,
              status: :available # Forces immediate ledger subtraction against their upcoming physical totals 
            )
          end
        end
      rescue StandardError => e
        Rails.logger.error("Commission Refunder Logic Failed: #{e.message}")
      end
    end
  end
end
