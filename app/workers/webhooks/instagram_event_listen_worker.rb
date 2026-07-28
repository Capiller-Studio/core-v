# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Webhooks
  class InstagramEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        payload = webhook.payload.with_indifferent_access
        entries = payload[:entry]

        return if entries.blank?

        instagram_id = entries.dig(0, :id)
        return if instagram_id.blank?

        # Use GlobalRouting to find the account/shard for this Instagram channel
        routing = GlobalRouting.find_by(route_type: "instagram", route_value: instagram_id.to_s)
        return if routing.blank?

        Current.set(account: routing.account) do
          channel = Channel::Instagram.find_by(instagram_id: instagram_id.to_s, account_id: routing.account_id)
          return unless channel_active?(channel)

          Channels::Instagram::EventListener.call(
            instagram_channel: channel,
            payload: payload
          )
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise e
      end
    end

    private

    def channel_active?(channel)
      return false if channel.blank?
      return false if channel.reauthorization_required?
      return false if channel.token_expired?
      return false unless channel.active?
      return false unless channel.account&.active?

      true
    end
  end
end
