# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Automations
  class ExecutionCleanupWorker
    include Sidekiq::Worker
    sidekiq_options queue: "maintenance", retry: 1

    # Retention period in days. Logs older than this are deleted.
    RETENTION_DAYS = 90

    # Runs daily via cron. Deletes old automation execution logs in batches
    # to avoid long-running transactions and excessive lock contention.
    def perform
      cutoff = RETENTION_DAYS.days.ago

      loop do
        deleted = AutomationExecution.where(executed_at: ...cutoff).limit(1000).delete_all
        break if deleted.zero?
      end
    end
  end
end
