# frozen_string_literal: true

module Affiliates
  module Payouts
    class Generator < ApplicationService
      attr_reader :profile

      def initialize(profile:)
        @profile = profile
      end

      def call
        return unless profile
        raise("Payouts disabled for this affiliate") unless profile.payouts_enabled?
        raise("Invalid Bank Details") unless profile.valid_bank_details?

        lock_key = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: profile.id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ActiveRecord::Base.transaction do
            # Strangle all 'available' ledgers strictly
            available_commissions = profile.commissions.available

            return if available_commissions.empty?

            total_payout = available_commissions.sum(:amount)

            # Guard: If refunds outpace current available revenue, we carry over the negative balance organically
            return if total_payout <= 0

            # Package them organically
            payout = profile.payouts.create!(
              amount: total_payout,
              currency: profile.currency,
              status: :processing,
              commission_ids: available_commissions.pluck(:id)
            )

            # Strangle double-spend risks
            # rubocop:disable Rails/SkipsModelValidations
            available_commissions.update_all(status: :paid)
            # rubocop:enable Rails/SkipsModelValidations

            # Generate PDF organically in background
            # Affiliates::Payouts::InvoicePdfWorker.perform_async(payout.id)

            payout
          end
        end
      rescue StandardError => e
        Rails.logger.error("Payout Manual Generation Failed: #{e.message}")
        nil
      end
    end
  end
end
