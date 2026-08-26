# frozen_string_literal: true

module Affiliates
  module Payouts
    class Processor < ApplicationService
      attr_reader :payout

      def initialize(payout:)
        @payout = payout
      end

      def call
        return if payout.paid?

        lock_key = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: payout.affiliate_profile_id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ActiveRecord::Base.transaction do
            process_payout!
          end
        end
      rescue StandardError => e
        handle_failure!(e)
        nil
      end

      private

      def process_payout!
        case payout.provider.to_sym
        when :manual
          process_manual!
        when :wise
          process_wise!
        end
      end

      def process_manual!
        payout.update!(status: :paid)
        Affiliates::Payouts::InvoiceWorker.perform_async(payout.id)
      end

      def process_wise!
        payout.update!(status: :processing)
        Affiliates::Wise::TransferWorker.perform_async(payout.id)
      end

      def handle_failure!(error)
        Rails.logger.error("Payout Processor Failed [Payout ID: #{payout.id}]: #{error.message}")
        ActiveRecord::Base.transaction do
          payout.update!(status: :failed)
          # Restore commissions to available status on failure to prevent lost balances
          if payout.commission_ids.present?
            # rubocop:disable Rails/SkipsModelValidations
            payout.profile.commissions.where(id: payout.commission_ids).update_all(status: :available)
            # rubocop:enable Rails/SkipsModelValidations
          end
        end
      rescue StandardError => rollback_error
        Rails.logger.error("Failed to restore commissions on payout failure: #{rollback_error.message}")
      end
    end
  end
end
