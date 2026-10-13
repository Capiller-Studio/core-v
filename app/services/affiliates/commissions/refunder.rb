# frozen_string_literal: true

module Affiliates
  module Commissions
    class Refunder < ApplicationService
      attr_reader :transaction, :refund_amount

      def initialize(transaction:, refund_amount: nil)
        @transaction = transaction
        @refund_amount = refund_amount
      end

      def call
        # A charge transaction was physically refunded or cancelled. Let's find its attached commission ledger.
        commission = ::Affiliate::Commission.find_by(transaction_record_id: transaction.id)
        return unless commission

        lock_key = format(::RedisUtilities::Keys::COMMISSION_LOCK, transaction_id: transaction.id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ActiveRecord::Base.transaction do
            if commission.pending? || commission.available?
              # It hasn't been paid out yet. 
              if full_refund?
                commission.voided!
              else
                # If partial refund, we leave it pending/available but create a negative adjustment
                issue_negative_commission(commission, status: commission.status)
              end
            elsif commission.paid?
              # It was already paid out previously. Issue a severe negative commission ledger entry.
              # This mathematically absorbs their next physical earnings preventing revenue bleeding natively.
              issue_negative_commission(commission, status: :available)
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("Commission Refunder Logic Failed: #{e.message}")
      end

      private

      def full_refund?
        refund_amount.nil? || refund_amount >= transaction.amount
      end

      def calculate_clawback_amount(commission)
        return commission.amount if full_refund?
        
        ratio = refund_amount.to_f / transaction.amount.to_f
        (commission.amount * ratio).round(2)
      end

      def issue_negative_commission(commission, status:)
        clawback_amount = calculate_clawback_amount(commission)
        
        ratio = full_refund? ? 1.0 : (refund_amount.to_f / transaction.amount.to_f)
        original_clawback_amount = (commission.original_amount * ratio).round(2)
        
        ::Affiliate::Commission.create!(
          affiliate_profile_id: commission.affiliate_profile_id,
          affiliate_referral_id: commission.affiliate_referral_id,
          transaction_record_id: commission.transaction_record_id,
          original_commission_id: commission.id,
          commission_type: :refund,
          original_amount: -original_clawback_amount,
          original_currency: commission.original_currency,
          exchange_rate: commission.exchange_rate,
          amount: -clawback_amount,
          currency: commission.currency,
          status: status
        )
      end
    end
  end
end
