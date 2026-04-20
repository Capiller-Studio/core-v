# frozen_string_literal: true

class EventBroadcastWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2, queue: "default"

  def perform(data, event, connection_tokens = nil)
    return if event.blank? || connection_tokens.blank?

    ActionCables::EventBroadcaster.call(
      data:,
      event:,
      connection_tokens:
    )
  end
end
