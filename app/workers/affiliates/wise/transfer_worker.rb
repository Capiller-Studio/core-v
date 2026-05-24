# frozen_string_literal: true

module Affiliates
  module Wise
    class TransferWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 5 # Exponential backoff for Wise API

      def perform(payout_id)
        payout = Affiliate::Payout.find_by(id: payout_id)
        return unless payout
        return if payout.paid? || payout.external_id.present?

        lock_key = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: payout.affiliate_profile_id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          Affiliates::Payouts::Wise::TransferCreator.call(payout: payout)
        end
      end
    end
  end
end
