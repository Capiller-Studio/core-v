# frozen_string_literal: true

class ImapFetchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  # TODO: Configure in scheduled.rb (e.g., every 2 minutes)

  def perform
    Channel::Email.where(status: :active).find_each do |email_channel|
      next unless email_channel.imap_enabled?

      Channels::Email::ImapFetcher.call(email_channel:)
    rescue StandardError => e
      Rails.logger.error("ImapFetchWorker failed for Channel::Email##{email_channel.id}: #{e.message}")
    end
  end
end
