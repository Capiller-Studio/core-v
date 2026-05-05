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
      rescue StandardError => e
        Rails.logger.error("Payout Manual Generation Failed: #{e.message}")
        nil
      end
    end
  end
end
