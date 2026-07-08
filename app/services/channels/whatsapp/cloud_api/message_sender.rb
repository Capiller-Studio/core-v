# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class MessageSender < ApplicationService
        attr_accessor :whatsapp_channel, :customer_inbox, :message

        def initialize(whatsapp_channel:, customer_inbox:, message:)
          self.whatsapp_channel = whatsapp_channel
          self.customer_inbox   = customer_inbox
          self.message          = message
        end

        def call
          if message.attachments.present?
            send_attachment_message
          elsif message.content.present?
            send_text_message
          end
        rescue StandardError => e
          log_exception(e)
        end

        private

        def send_text_message
          response = HTTParty.post(
            "#{whatsapp_channel.phone_number_endpoint}/messages",
            headers: whatsapp_channel.api_headers,
            body: {
              messaging_product: "whatsapp",
              context: message_context,
              to: customer_inbox.customer.full_phone_number,
              text: { body: Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) },
              type: "text"
            }.to_json
          )

          process_response(response)
        end

        def send_attachment_message
          attachment = message.attachments.first
          attachment_type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : "document"

          attachment_content = { link: attachment.direct_download_url }
          attachment_content["caption"] = Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) unless %w[audio sticker].include?(attachment_type)
          attachment_content["filename"] = attachment.file.filename.to_s if attachment_type == "document"

          response = HTTParty.post(
            "#{whatsapp_channel.phone_number_endpoint}/messages",
            headers: whatsapp_channel.api_headers,
            body: {
              messaging_product: "whatsapp",
              context: message_context,
              to: customer_inbox.customer.full_phone_number,
              type: attachment_type,
              attachment_type.to_s => attachment_content
            }.to_json
          )

          process_response(response)
        end

        def process_response(response)
          if response.success?
            message.update!(external_id: response.parsed_response.dig("messages", 0, "id"))
          else
            whatsapp_channel.authorization_error! if response.unauthorized?
            message.update!(status: :failed)
            Rails.logger.error("WhatsApp Message Sender Error: #{response.parsed_response}")
          end
        end

        def log_exception(error)
          message.update!(status: :failed)
          Rails.logger.error("WhatsApp MessageSender exception for #{whatsapp_channel.full_phone_number}: #{error.message}")

          if error.to_s.include?("OAuthException") || error.to_s.include?("Error validating access token")
            whatsapp_channel.authorization_error!
          end
        end

        def message_context
          return if message.external_reply_to_id.blank?

          { message_id: message.external_reply_to_id }
        end
      end
    end
  end
end
