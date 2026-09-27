# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.3.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class MessageSender < ApplicationService
      include Channels::Concerns::MetaWindowPolicy

      FALLBACK_TAG = "ACCOUNT_UPDATE"
      HUMAN_AGENT_TAG = "HUMAN_AGENT"

      attr_accessor :facebook_page_channel, :customer_inbox, :message

      def initialize(facebook_page_channel:, customer_inbox:, message:)
        self.facebook_page_channel    = facebook_page_channel
        self.customer_inbox           = customer_inbox
        self.message                  = message
      end

      def call
        # TODO: Important -> Use correct shard based on current-account
        if customer_inbox.external_id.blank?
          handle_missing_recipient
          return
        end

        send_message(params) if message.content.present?

        message.attachments.each do |attachment|
          url = Channels::AudioTranscoder.ensure_compatible_audio_url(attachment, channel_type: :facebook_page)
          next if url.blank?

          send_message(attachment_params(attachment, url))
        end
      rescue Facebook::Messenger::FacebookError => e
        log_exception(e)
      rescue StandardError => e
        raise(e) if transient_network_error?(e)

        log_exception(e)
      end

      private

      def handle_missing_recipient
        Rails.logger.warn("[FacebookPages::MessageSender] Recipient external_id missing for message #{message.id}")
        message.update!(
          status: :failed,
          data: (message.data || {}).merge("error_message" => "Recipient Facebook ID is missing")
        )
      end

      def send_message(payload)
        deliver_payload(payload)
      rescue Facebook::Messenger::FacebookError => e
        if retryable_window_error?(e) && payload[:tag] != FALLBACK_TAG
          retry_payload = payload.merge(messaging_type: "MESSAGE_TAG", tag: FALLBACK_TAG)
          deliver_payload(retry_payload)
        else
          raise(e)
        end
      end

      def deliver_payload(payload)
        response = Facebook::Messenger::Bot.deliver(payload, page_id: facebook_page_channel.page_identifier)
        response = JSON.parse(response)

        if response["error"].present?
          if retryable_window_error_hash?(response["error"]) && payload[:tag] != FALLBACK_TAG
            retry_payload = payload.merge(messaging_type: "MESSAGE_TAG", tag: FALLBACK_TAG)
            return deliver_payload(retry_payload)
          end

          return log_error(response)
        end

        message.update!(external_id: response["message_id"]) if response["message_id"].present?
      end

      def params
        payload = {
          recipient: { id: customer_inbox.external_id },
          message: { text: Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) }
        }.merge(messaging_type_params)

        reply_id = message.external_reply_to_id
        payload[:reply_to] = { mid: reply_id } if reply_id.present?
        payload
      end

      def attachment_params(attachment, url = attachment.direct_download_url)
        {
          recipient: { id: customer_inbox.external_id },
          message: {
            attachment: {
              type: attachment_type(attachment),
              payload: {
                url: url
              }
            }
          }
        }.merge(messaging_type_params)
      end

      def messaging_type_params
        # Within standard Meta 24-hour service window: standard RESPONSE messaging
        return { messaging_type: "RESPONSE" } unless outside_24_hours?

        { messaging_type: "MESSAGE_TAG", tag: determine_message_tag }
      end

      def determine_message_tag
        if human_agent_eligible?
          HUMAN_AGENT_TAG
        else
          FALLBACK_TAG
        end
      end

      def human_agent_eligible?
        return false unless human_agent_sender?
        return false if outside_7_days?

        true
      end

      def retryable_window_error?(error)
        msg = error.message.to_s
        msg.include?("outside of allowed window") || msg.include?("24-hour") || msg.include?("(#10)") || msg.include?("(#230)") || msg.include?("human_agent")
      end

      def retryable_window_error_hash?(error_hash)
        return false unless error_hash.is_a?(Hash)

        code = error_hash["code"].to_i
        msg = error_hash["message"].to_s
        code == 10 || code == 230 || msg.include?("outside of allowed window") || msg.include?("24-hour") || msg.include?("human_agent")
      end

      def attachment_type(attachment)
        case attachment.attachment_type.to_s
        when "image" then "image"
        when "audio" then "audio"
        when "video" then "video"
        else "file"
        end
      end

      def log_error(response)
        error_data = response["error"] || {}
        error_code = error_data["code"]
        error_message = error_data["message"] || "Failed to send Facebook message"

        facebook_page_channel.authorization_error! if error_code == 190 || error_message.to_s.include?("The session has been invalidated") || error_message.to_s.include?("Error validating access token")

        message.update!(
          status: :failed,
          data: (message.data || {}).merge(
            "error_code" => error_code,
            "error_message" => error_message
          )
        )

        Rails.logger.error("[FacebookPages::MessageSender] Error sending message: code=#{error_code} message=#{error_message}")
      end

      def log_exception(error)
        message.update!(
          status: :failed,
          data: (message.data || {}).merge("error_message" => error.message)
        )

        if error.to_s.include?("The session has been invalidated") || error.to_s.include?("Error validating access token")
          facebook_page_channel.authorization_error!
        end

        Rails.logger.error("Facebook MessageSender error for page #{facebook_page_channel.page_identifier}: #{error.message}")
      end

      def transient_network_error?(error)
        error.message.to_s.include?("transient error") ||
          error.is_a?(Net::OpenTimeout) ||
          error.is_a?(Net::ReadTimeout) ||
          error.is_a?(Errno::ECONNRESET) ||
          error.is_a?(Errno::ECONNREFUSED) ||
          error.is_a?(SocketError) ||
          (error.respond_to?(:response) && [429, 500, 502, 503, 504].include?(error.response&.code.to_i))
      end
    end
  end
end
