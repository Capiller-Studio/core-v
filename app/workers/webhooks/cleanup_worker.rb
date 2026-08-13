# frozen_string_literal: true

module Webhooks
  class CleanupWorker
    include Sidekiq::Worker
    sidekiq_options queue: "low", retry: 3

    def perform
      # Delete processed webhooks older than 14 days to prevent DB bloat
      Webhook::Incoming.where(status: :processed)
                       .where(created_at: ...14.days.ago)
                       .find_in_batches(batch_size: 1000) do |batch|
        Webhook::Incoming.where(id: batch.map(&:id)).delete_all
      end
    end
  end
end
