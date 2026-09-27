# frozen_string_literal: true

module AssignmentPolicies
  # Asynchronous worker to drain unassigned conversation backlogs.
  #
  # Uses distributed Redis mutex locking to ensure multiple concurrent
  # triggers (e.g. rapid agent connections) do not redundantly process
  # the same queue simultaneously.
  #
  class QueueDrainWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 2

    LOCK_TIMEOUT = 15.seconds

    def perform(account_id, inbox_id = nil)
      lock_key = format(
        RedisUtilities::Keys::QUEUE_DRAIN_LOCK,
        account_id: account_id,
        inbox_id: inbox_id || 'all'
      )

      # If another worker is already draining this queue, skip gracefully
      return if RedisUtilities::MutexHelpers.locked?(lock_key)

      RedisUtilities::MutexHelpers.with_lock(lock_key, timeout: LOCK_TIMEOUT, wait_timeout: 0.seconds) do
        QueueDrainer.call(account_id: account_id, inbox_id: inbox_id)
      end
    rescue MutexLockError
      # Another worker acquired the lock concurrently; exit safely
      nil
    end
  end
end
