# frozen_string_literal: true

require "sidekiq/api"

module Webhooks
  class RetryFailedWorker
    include Sidekiq::Worker

    # Cron-style fail-safe sweeper — no mutex needed, no heavy retries
    sidekiq_options queue: "default", retry: 3

    # Map sources to their respective listener workers
    WORKER_MAPPING = {
      "stripe"     => "Webhooks::StripeEventListenWorker",
      "paddle"     => "Webhooks::PaddleEventListenWorker",
      "twilio"     => "Webhooks::TwilioEventListenWorker",
      "signalwire" => "Webhooks::SignalwireEventListenWorker",
      "aws_sns"    => "Webhooks::AwsSnsEventListenWorker",
      "whatsapp"   => "Webhooks::WhatsappEventListenWorker",
      "custom"     => "Webhooks::CustomEventListenWorker",
      "instagram"  => "Webhooks::InstagramEventListenWorker",
      "facebook"   => "Webhooks::FacebookEventListenWorker"
    }.freeze

    # A pending webhook older than this is assumed orphaned (Sidekiq crashed before enqueue)
    ORPHANED_PENDING_THRESHOLD = 1.hour

    # After this many fail-safe attempts, give up and flag for manual review
    MAX_FAIL_SAFE_RETRIES = 3

    # Called explicitly with a webhook_id for manual one-off retry, or with no args for a full sweep
    def perform(webhook_id = nil)
      if webhook_id
        webhook = Webhook::Incoming.find_by(id: webhook_id, status: :failed)
        return unless webhook

        retry_webhook(webhook)
      else
        sweep_and_retry
      end
    end

    private

    def sweep_and_retry
      active_ids = fetch_active_webhook_ids

      # Scope at the DB level to avoid loading rows we can't do anything about
      candidates = Webhook::Incoming
        .where(status: [:failed, :pending])
        .where(
          "(status = ? AND created_at < ?) OR status = ?",
          Webhook::Incoming.statuses[:pending],
          ORPHANED_PENDING_THRESHOLD.ago,
          Webhook::Incoming.statuses[:failed]
        )

      candidates.find_each do |webhook|
        # Sidekiq is still managing this one — leave it alone
        next if active_ids.include?(webhook.id)

        if webhook.fail_safe_retries >= MAX_FAIL_SAFE_RETRIES
          webhook.update!(status: :permanently_failed,
                          error_message: "Marked permanently_failed after #{MAX_FAIL_SAFE_RETRIES} fail-safe retry attempts.")
          Rails.logger.error("[Webhooks::RetryFailedWorker] Webhook ##{webhook.id} (#{webhook.source}) permanently failed. Manual review required.")
          next
        end

        webhook.increment!(:fail_safe_retries)
        retry_webhook(webhook)
      end
    end

    # Scan all Sidekiq queues + the retry set to build the set of webhook IDs
    # that Sidekiq is actively aware of. This prevents double-enqueuing.
    def fetch_active_webhook_ids
      active_ids = Set.new

      # Scan every queue (not just "default") so we don't miss dedicated queues
      Sidekiq::Queue.all.each do |queue| # rubocop:disable Rails/FindEach
        queue.each do |job|
          next unless webhook_event_listener?(job.klass)

          active_ids.add(job.args.first)
        end
      end

      # Webhooks sitting in Sidekiq's exponential-backoff retry set
      Sidekiq::RetrySet.new.each do |job|
        next unless webhook_event_listener?(job.klass)

        active_ids.add(job.args.first)
      end

      # Webhooks currently being executed by a Sidekiq worker process
      Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
        klass = work.dig("payload", "class")
        next unless webhook_event_listener?(klass)

        active_ids.add(work.dig("payload", "args")&.first)
      end

      active_ids.compact
    end

    def webhook_event_listener?(klass)
      klass.to_s.start_with?("Webhooks::") && klass.to_s.end_with?("EventListenWorker")
    end

    def retry_webhook(webhook)
      worker_class_name = WORKER_MAPPING[webhook.source]

      unless worker_class_name
        Rails.logger.error("[Webhooks::RetryFailedWorker] Unknown source '#{webhook.source}' for Webhook::Incoming##{webhook.id}. No worker mapped.")
        return
      end

      worker_class_name.constantize.perform_async(webhook.id)
    end
  end
end
