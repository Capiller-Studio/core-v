# frozen_string_literal: true

module AssignmentPolicies
  # Tracks whether an account has unassigned backlog conversations using Redis
  # as a fast, zero-overhead gatekeeper.
  #
  # Three states:
  #   - "1": Backlog definitely exists.
  #   - "0": Backlog confirmed empty (cleared after QueueDrainer finds 0 unassigned).
  #   - nil: Cold start / Redis restart. Allowed to run once (subject to 60s throttle).
  #
  module BacklogTracker
    class << self
      def backlog_key(account_id)
        format(RedisUtilities::Keys::BACKLOG_STATUS, account_id: account_id)
      end

      # Returns true if backlog is known to exist or status is uninitialized (nil).
      # Returns false only if confirmed empty ("0").
      def backlog_pending?(account_id)
        status = RedisUtilities::Helpers.get(backlog_key(account_id))
        status != "0"
      rescue StandardError => e
        Rails.logger.warn("Failed to read BACKLOG_STATUS from Redis: #{e.message}")
        true
      end

      def mark_backlog_exists(account_id)
        RedisUtilities::Helpers.set(backlog_key(account_id), "1")
      rescue StandardError => e
        Rails.logger.warn("Failed to mark backlog in Redis for account #{account_id}: #{e.message}")
      end

      def mark_backlog_cleared(account_id)
        RedisUtilities::Helpers.set(backlog_key(account_id), "0")
      rescue StandardError => e
        Rails.logger.warn("Failed to clear backlog in Redis for account #{account_id}: #{e.message}")
      end
    end
  end
end
