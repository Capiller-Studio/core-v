# frozen_string_literal: true

module Affiliates
  module Commissions
    class Calculator < ApplicationService
      attr_reader :transaction

      def initialize(transaction:)
        @transaction = transaction
      end

      def call
        return unless transaction.charge? && transaction.completed?

        lock_key = format(::RedisUtilities::Keys::COMMISSION_LOCK, transaction_id: transaction.id)
        
        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ActiveRecord::Base.transaction do
            process_commission
          end
        end
      rescue StandardError => e
        Rails.logger.error("Commission Calculation Failed: #{e.message}")
      end

      private

      def process_commission
        referral = ::Affiliate::Referral.active.find_by(account_id: transaction.account_id)
        return unless referral

        # Guard: Check Tenure
        if referral.remaining_tenure_months <= 0
          referral.expired!
          return
        end

        profile = referral.profile

        # Calculate Base Rate natively (in Original Currency)
        original_calculated_cut = (transaction.amount * (profile.commission_rate / 100.0)).round(2)

        # Map through Forex Scaling bridging their custom currency mapping natively
        exchange_rate = Affiliates::CurrencyConverter.call(from_currency: transaction.currency, to_currency: profile.currency) || 1.0
        final_localized_amount = (original_calculated_cut * exchange_rate).round(2)

        # Apply Capping Limit dynamically if configured natively
        if profile.max_earnings_per_account.present?
          previous_earnings = referral.total_commission
          available_headroom = [ profile.max_earnings_per_account - previous_earnings, 0 ].max

          if final_localized_amount >= available_headroom
            final_localized_amount = available_headroom
            referral.expired! # Max Cap hit safely
          end
        end

        return if final_localized_amount <= 0

        ::Affiliate::Commission.create!(
          profile: profile,
          referral: referral,
          transaction_record: transaction,
          original_amount: original_calculated_cut,
          original_currency: transaction.currency,
          exchange_rate: exchange_rate,
          amount: final_localized_amount,
          currency: profile.currency,
          status: profile.holding_days.to_i.zero? ? :available : :pending
        )
      end
    end
  end
end
