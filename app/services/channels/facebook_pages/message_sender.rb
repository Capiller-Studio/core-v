# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class MessageSender < ApplicationService
      attr_accessor :facebook_page_channel, :customer_inbox, :message

      def initialize(facebook_page_channel:, customer_inbox:, message:)
        self.facebook_page_channel    = facebook_page_channel
        self.customer_inbox           = customer_inbox
        self.message                  = message
      end

      def call
        # TODO: Important -> Use correct shard based on current-account

        send_message(params) if message.content.present?

        message.attachments.each do |attachment|
          send_message(attachment_params(attachment))
        end
      rescue Facebook::Messenger::FacebookError => e
        log_exception(e)
        # TODO: Exception handling
      end

      private

      def send_message(params)
        response = Facebook::Messenger::Bot.deliver(params, page_id: facebook_page_channel.page_identifier)
        response = JSON.parse(response)

        return log_error(response) if response["error"].present?

        # TODO: Changing message.external_id to array
        message.update!(external_id: response["message_id"]) if response["message_id"].present?
      end

      def params
        {
          recipient: { id: customer_inbox.external_id },
          message: { text: Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) },
          messaging_type: "RESPONSE"
        }
      end

      def attachment_params(attachment)
        {
          recipient: { id: customer_inbox.external_id },
          message: {
            attachment: {
              type: attachment_type(attachment),
              payload: {
                url: attachment.direct_download_url
              }
            }
          },
          messaging_type: "RESPONSE"
        }
      end

      def attachment_type(attachment)
        return attachment.attachment_type if %w[image audio video file].include?(attachment.attachment_type)

        "file"
      end

      def log_error(_response)
        # TODO: Error handling
        message.update!(status: :failed)
      end

      def log_exception(error)
        message.update!(status: :failed)

        if error.to_s.include?("The session has been invalidated") || error.to_s.include?("Error validating access token")
          facebook_page_channel.authorization_error!
        end

        Rails.logger.error("Facebook MessageSender error for page #{facebook_page_channel.page_identifier}: #{error.message}")
      end
    end
  end
end
