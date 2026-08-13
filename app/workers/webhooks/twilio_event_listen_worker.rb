# frozen_string_literal: true

module Webhooks
  class TwilioEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        route_params = webhook.route_params
        channel_id = route_params[:channel_id]
        account_id = route_params[:account_id]

        channel = Channel::ShortMessage.twilio.find_by(account_id: account_id, id: channel_id)
        raise("Channel not found for account #{account_id} and channel #{channel_id}") unless channel

        Channels::ShortMessage::Twilio::ConversationCreator.call(
          short_message_channel: channel,
          parsed_params: webhook.payload
        )

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise(e)
      end
    end
  end
end
