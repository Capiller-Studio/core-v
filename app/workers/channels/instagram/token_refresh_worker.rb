# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class TokenRefreshWorker
      include Sidekiq::Worker

      sidekiq_options queue: :scheduled, retry: 3

      # Runs daily. Finds all Instagram channels whose tokens expire within the
      # next 7 days and refreshes them. Instagram long-lived tokens are valid for
      # 60 days and can be refreshed as long as they are at least 24 hours old
      # and have not yet expired.
      def perform
        active_shards = Account.distinct.pluck(:shard_key)

        active_shards.each do |shard_key|
          ShardRecord.connected_to(shard: shard_key.to_sym, role: :writing) do
            Channel::Instagram.where("expires_at < ?", 7.days.from_now)
                              .where("expires_at > ?", Time.current)
                              .where(status: :active)
                              .find_each do |channel|
              channel.refresh_token!
              Rails.logger.info("Refreshed Instagram token for #{channel.instagram_id} (account #{channel.account_id})")
            rescue StandardError => e
              Rails.logger.error("Failed to refresh Instagram token for #{channel.instagram_id}: #{e.message}")
            end
          end
        end
      end
    end
  end
end
