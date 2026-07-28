# frozen_string_literal: true

module Webhooks
  class AwsSnsEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        route_params = webhook.route_params
        channel_id = route_params[:channel_id]
        account_id = route_params[:account_id]
        
        aws_json = webhook.payload

        channel = Channel::ShortMessage.aws_sns.find_by(account_id: account_id, id: channel_id)
        raise "Channel not found for account #{account_id} and channel #{channel_id}" unless channel

        if aws_json["Type"] == "SubscriptionConfirmation"
          HTTParty.get(aws_json["SubscribeURL"]) if aws_json["SubscribeURL"]
        elsif aws_json["Type"] == "Notification"
          Channels::ShortMessage::AwsSns::ConversationCreator.call(
            short_message_channel: channel,
            parsed_params: aws_json
          )
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise e
      end
    end
  end
end
