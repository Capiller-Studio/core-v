# frozen_string_literal: true

class ImapFetchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  # Scheduled via whenever gem every 2 minutes — see config/schedule.rb

  def perform
    Account.pluck(:shard_key).uniq.compact.each do |shard| # rubocop:disable Performance/ChainArrayAllocation
      ShardRecord.connected_to(shard: shard.to_sym, role: :writing) do
        Channel::Email.imap_enabled.where(status: :active).find_each do |email_channel|
          Channels::Email::ImapFetcher.call(email_channel:)
        rescue StandardError => e
          Rails.logger.error("ImapFetchWorker failed for Channel::Email##{email_channel.id}: #{e.message}")
        end
      end
    end
  end
end
