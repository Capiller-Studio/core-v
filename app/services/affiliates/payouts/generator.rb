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
            # Pessimistic row locking on available commissions to avoid concurrent double-claims
            commission_records = profile.commissions.available.lock("FOR UPDATE").to_a
            return if commission_records.empty?

            total_payout = commission_records.sum(&:amount)
            # Guard: If negative adjustments outpace available commissions, carry balance over
            return if total_payout <= 0

            commission_ids = commission_records.map(&:id)

            payout = profile.payouts.create!(
              amount: total_payout,
              currency: profile.currency,
              status: :processing,
              commission_ids: commission_ids
            )

            # rubocop:disable Rails/SkipsModelValidations
            profile.commissions.where(id: commission_ids).update_all(status: :paid)
            # rubocop:enable Rails/SkipsModelValidations

            payout
          end
        end
      rescue StandardError => e
        Rails.logger.error("Payout Manual Generation Failed [Profile ID: #{profile&.id}]: #{e.message}")
        nil
      end
    end
  end
end
