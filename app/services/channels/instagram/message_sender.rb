# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class MessageSender < ApplicationService
      attr_accessor :instagram_channel, :customer_inbox, :message

      def initialize(instagram_channel:, customer_inbox:, message:)
        self.instagram_channel = instagram_channel
        self.customer_inbox    = customer_inbox
        self.message           = message
      end

      def call
        return if message.content.blank? && message.attachments.blank?

        send_message(params) if message.content.present?

        message.attachments.each do |attachment|
          send_message(attachment_params(attachment))
        end
      rescue StandardError => e
        log_exception(e)
      end

      private

      def send_message(params)
        # Instagram Graph API uses the same delivery mechanism as Facebook Pages
        # but requires the page_access_token associated with the Instagram account
        response = Facebook::Messenger::Bot.deliver(params, access_token: instagram_channel.access_token)
        response = JSON.parse(response)

        return log_error(response) if response["error"].present?

        message.update!(external_id: response["message_id"], status: :delivered) if response["message_id"].present?
      end

      def params
        {
          recipient: { id: customer_inbox.external_id },
          message: { text: message.content }
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
          }
        }
      end

      def attachment_type(attachment)
        return attachment.attachment_type if %w[image audio video file].include?(attachment.attachment_type)
        "file"
      end

      def log_error(response)
        message.update!(status: :failed)
        error = response["error"]
        Rails.logger.error("Instagram send error for #{instagram_channel.instagram_id}: #{error}")

        if error.is_a?(Hash) && error["code"].to_i == 190
          instagram_channel.authorization_error!
        end
      end

      def log_exception(error)
        message.update!(status: :failed)
        Rails.logger.error("Instagram send exception for #{instagram_channel.instagram_id}: #{error.message}")

        if error.to_s.include?("The session has been invalidated") || error.to_s.include?("Error validating access token")
          instagram_channel.authorization_error!
        end
      end
    end
  end
end
