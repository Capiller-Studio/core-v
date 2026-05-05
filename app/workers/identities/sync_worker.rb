# frozen_string_literal: true

module Identities
  class SyncWorker < BaseMutexWorker
    sidekiq_options queue: :default, retry: 3

    def perform(customer_id, identity_source_id)
      customer = Customer.find_by(id: customer_id)
      identity_source = IdentitySource.find_by(id: identity_source_id)

      return unless customer && identity_source && identity_source.api?

      account = customer.account

      lock_key = "IDENTITY_SYNC_LOCK:#{customer.id}:#{identity_source.id}"

      # Wrapped in Redis Mutex Lock to avoid redundant concurrent request spawning
      RedisUtilities::MutexHelpers.with_lock(lock_key) do
        # Wrap everything in DB transaction
        ActiveRecord::Base.transaction do
          # 1. Check if identity already exists
          identity = account.identities.find_by(
            customer_id: customer.id,
            identity_source_id: identity_source.id,
            identity_type: :custom_api
          )

          # Stop if already successfully fetched (or if user wants continuous sync, they would trigger standard updates)
          # For auto-sync, we only sync if the identity doesn't exist yet.
          return if identity.present?

          # 2. Stub the identity to track existence immediately
          identity = account.identities.create!(
            customer: customer,
            identity_source: identity_source,
            identity_type: :custom_api,
            identifier: SecureRandom.uuid, # Temporary or auto-generated until API replaces it if configured
            external_id: customer.external_id
          )

          # 3. Call Fetcher
          Identities::ApiFetcher.call(identity: identity)
        end
      end
    rescue MutexLockError
      Rails.logger.warn("IdentitySyncWorker lock acquired elsewhere for customer_id: #{customer_id}, identity_source_id: #{identity_source_id}")
    rescue StandardError => e
      Rails.logger.error("IdentitySyncWorker failed for customer_id: #{customer_id}, identity_source_id: #{identity_source_id}. Error: #{e.message}")
      raise(e) # Re-raise for Sidekiq retry mechanism
    end
  end
end
