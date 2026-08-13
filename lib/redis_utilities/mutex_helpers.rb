# frozen_string_literal: true

module RedisUtilities
  class MutexHelpers
    TIMEOUT = 10.seconds

    def self.with_lock(key, timeout: TIMEOUT, wait_timeout: 5.seconds)
      acquired = false
      start_time = Time.current

      while Time.current - start_time < wait_timeout
        if lock(key, timeout: timeout)
          acquired = true
          break
        end
        sleep(0.1)
      end

      if acquired
        begin
          yield
        ensure
          unlock(key)
        end
      else
        raise(MutexLockError, "Could not acquire lock #{key}")
      end
    end

    def self.lock(key, timeout: TIMEOUT)
      value = Time.now.to_f.to_s

      RedisUtilities::Helpers.set(key, value, overwrite: false, expiry: timeout.to_i)
    end

    def self.unlock(key)
      RedisUtilities::Helpers.delete(key)
      true
    end

    def self.locked?(key)
      RedisUtilities::Helpers.exists?(key)
    end
  end
end
