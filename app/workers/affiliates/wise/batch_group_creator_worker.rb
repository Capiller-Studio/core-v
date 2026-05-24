# frozen_string_literal: true

module Affiliates
  module Wise
    class BatchGroupCreatorWorker
      include Sidekiq::Worker

      sidekiq_options queue: :payouts, retry: 5

      def perform(payout_batch_id)
        batch = Affiliate::PayoutBatch.find_by(id: payout_batch_id)
        return unless batch
        return if batch.external_id.present?

        lock_key = "wise:batch_creator:#{batch.id}"

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          external_id = Affiliates::Payouts::Wise::BatchGroupCreator.call(payout_batch: batch)
          
          if external_id
            batch.payouts.find_each do |payout|
              # Queue transfer workers for each child payout
              Affiliates::Payouts::Processor.call(payout: payout)
            end
          end
        end
      end
    end
  end
end
