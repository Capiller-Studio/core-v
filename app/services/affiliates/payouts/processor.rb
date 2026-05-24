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
        payout.update!(status: :failed)
        Rails.logger.error("Payout Processor Failed [Payout ID: #{payout.id}]: #{e.message}")
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
      end

      def process_wise!
        # Hand off Wise payout to background worker for fault tolerance
        payout.update!(status: :processing)
        Affiliates::Wise::TransferWorker.perform_async(payout.id)
      end
    end
  end
end
