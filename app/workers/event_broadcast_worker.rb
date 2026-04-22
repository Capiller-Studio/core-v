# frozen_string_literal: true

class EventBroadcastWorker
  include Sidekiq::Worker
  sidekiq_options retry: 2, queue: "default"

  def perform(data, event, connection_tokens = nil, account_id = nil)
    return if event.blank? || connection_tokens.blank?

    ActionCables::EventBroadcaster.call(
      data:,
      event:,
      connection_tokens:
    )

    if account_id.present?
      account = Account.find_by(id: account_id)
      return unless account

      parsed_payload = JSON.parse(data) rescue {}
      Integrations::EventDispatcher.call(event_name: event, payload: parsed_payload, account: account)
    end
  end
end
