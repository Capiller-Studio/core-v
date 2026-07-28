# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class BaseMutexWorker
    include Sidekiq::Worker

    MUTEX_LOCK_RETRY_LIMIT = 25

    sidekiq_options queue: "default", retry: MUTEX_LOCK_RETRY_LIMIT

    sidekiq_retry_in do |count, exception|
      if exception.is_a?(MutexLockError)
        # Exponential backoff: 1s, 2s, 4s, 8s, 16s
        (2**count)
      end
    end
end
