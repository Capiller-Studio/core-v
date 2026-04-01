# frozen_string_literal: true

module Messages
  class StatusUpdateWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: "default"

    def perform(account_id, status, params = {})
      params = params.with_indifferent_access
      Messages::StatusUpdater.call(account_id: account_id, status: status, params: params)
    end
  end
end
