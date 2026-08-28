# frozen_string_literal: true

require "sidekiq/api"

module Integrations
  module Webhooks
    class DeliveryRetryWorker
      include Sidekiq::Worker
      sidekiq_options queue: "default", retry: 3

      ORPHANED_PENDING_THRESHOLD = 1.hour
      MAX_FAIL_SAFE_RETRIES = 3

      # Called with (account_id, delivery_id) for manual one-off retry, or with no args for full multi-shard sweep
      def perform(account_id = nil, delivery_id = nil)
        if account_id.present? && delivery_id.present?
          account = Account.find_by(id: account_id)
          return unless account

          account.with_shard do
            delivery = account.webhook_deliveries.find_by(id: delivery_id)
            return unless delivery

            retry_delivery(account.id, delivery)
          end
        else
          sweep_and_retry
        end
      end

      private

      def sweep_and_retry
        active_ids = fetch_active_delivery_ids
        active_shards = Account.distinct.pluck(:shard_key).compact

        active_shards.each do |shard_key|
          ShardRecord.connected_to(shard: shard_key.to_sym, role: :writing) do
            candidates = Webhook::Delivery
              .where(status: :pending)
              .where("created_at < ?", ORPHANED_PENDING_THRESHOLD.ago)

            candidates.find_each do |delivery|
              next if active_ids.include?(delivery.id)

              if delivery.attempts.count >= MAX_FAIL_SAFE_RETRIES
                delivery.failed!
                Rails.logger.warn("[Integrations::Webhooks::DeliveryRetryWorker] Delivery ##{delivery.id} marked failed after #{MAX_FAIL_SAFE_RETRIES} attempts on shard #{shard_key}.")
                next
              end

              retry_delivery(delivery.account_id, delivery)
            end
          end
        end
      end

      def retry_delivery(account_id, delivery)
        next_attempt = delivery.attempts.count + 1
        resource = delivery.resource

        if resource.is_a?(Integration) && resource.slack?
          Integrations::Slack::NotifierWorker.perform_async(account_id, delivery.id, next_attempt)
        else
          Integrations::Webhooks::BroadcasterWorker.perform_async(account_id, delivery.id, next_attempt)
        end
      end

      def fetch_active_delivery_ids
        active_ids = Set.new

        Sidekiq::Queue.all.each do |queue|
          queue.each do |job|
            next unless delivery_worker?(job.klass)

            active_ids.add(job.args[1]) if job.args[1].present?
          end
        end

        Sidekiq::RetrySet.new.each do |job|
          next unless delivery_worker?(job.klass)

          active_ids.add(job.args[1]) if job.args[1].present?
        end

        Sidekiq::ScheduledSet.new.each do |job|
          next unless delivery_worker?(job.klass)

          active_ids.add(job.args[1]) if job.args[1].present?
        end

        Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
          klass = work.dig("payload", "class")
          next unless delivery_worker?(klass)

          args = work.dig("payload", "args")
          active_ids.add(args[1]) if args.is_a?(Array) && args[1].present?
        end

        active_ids.compact
      end

      def delivery_worker?(klass)
        klass_name = klass.to_s
        klass_name == "Integrations::Webhooks::BroadcasterWorker" || klass_name == "Integrations::Slack::NotifierWorker"
      end
    end
  end
end
