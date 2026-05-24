# frozen_string_literal: true

module Affiliates
  module Wise
    class BatchFunderWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 5

      def perform(payout_batch_id)
        batch = Affiliate::PayoutBatch.find_by(id: payout_batch_id)
        return unless batch
        return if batch.completed?

        # Prevent concurrent fundings on the same batch
        lock_key = "wise:batch_funder:#{batch.id}"

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          Affiliates::Payouts::Wise::BatchFunder.call(payout_batch: batch)
        end
      end
    end
  end
end
