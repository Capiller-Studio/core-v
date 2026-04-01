# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Webhooks
  class InstagramEventListenWorker < BaseMutexWorker
    def perform(payload = {})
      payload = payload.with_indifferent_access
      entries = payload[:entry]

      return if entries.blank?

      instagram_id = entries.dig(0, :id)
      return if instagram_id.blank?

      channel = find_channel(instagram_id)
      return unless channel_active?(channel)

      Channels::Instagram::EventListner.call(
        instagram_channel: channel,
        payload: payload
      )
    end

    private

    def find_channel(instagram_id)
      Channel::FacebookPage.find_by(instagram_id: instagram_id)
    end

    def channel_active?(channel)
      return false if channel.blank?
      return false if channel.reauthorization_required?
      return false unless channel.active?
      return false unless channel.account&.active?

      true
    end
  end
end
