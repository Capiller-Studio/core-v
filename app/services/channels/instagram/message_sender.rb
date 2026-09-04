# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class MessageSender < ApplicationService
      include Channels::Concerns::MetaWindowPolicy

      attr_accessor :instagram_channel, :customer_inbox, :message

      def initialize(instagram_channel:, customer_inbox:, message:)
        self.instagram_channel = instagram_channel
        self.customer_inbox    = customer_inbox
        self.message           = message
      end

      def call
        return if message.content.blank? && message.attachments.blank?

        if customer_inbox.external_id.blank?
          handle_missing_recipient
          return
        end

        send_message(params) if message.content.present?

        message.attachments.each do |attachment|
          url = attachment.direct_download_url
          next if url.blank?

          send_message(attachment_params(attachment, url))
        end
      rescue StandardError => e
        raise(e) if transient_network_error?(e)

        log_exception(e)
      end

      private

      def handle_missing_recipient
        Rails.logger.warn("[Instagram::MessageSender] Recipient external_id missing for message #{message.id}")
        message.update!(
          status: :failed,
          data: (message.data || {}).merge("error_message" => "Recipient Instagram ID is missing")
        )
      end

      def send_message(payload)
        response = post_to_instagram(payload)
        result = parse_response(response)

        if response.respond_to?(:code) && transient_error?(response.code.to_i, result.dig("error", "code").to_i)
          Rails.logger.warn("Instagram transient error (#{response.code}) for #{instagram_channel.instagram_id}, raising for Sidekiq retry")
          raise("Instagram API transient error (#{response.code}): #{result.dig('error', 'message')}")
        end

        if (!response.success? || result["error"].present?) && payload[:tag].present? && tag_error?(result["error"])
          retry_payload = payload.except(:tag)
          response = post_to_instagram(retry_payload)
          result = parse_response(response)
        end

        return log_error(result) if !response.success? || result["error"].present?

        message.update!(external_id: result["message_id"], status: :delivered) if result["message_id"].present?
      end

      def parse_response(response)
        JSON.parse(response.body)
      rescue StandardError
        {}
      end

      def post_to_instagram(payload)
        HTTParty.post(
          "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/me/messages",
          headers: { "Content-Type" => "application/json" },
          query: { access_token: instagram_channel.access_token },
          body: payload.to_json
        )
      end

      def params
        payload = {
          recipient: { id: customer_inbox.external_id },
          message: { text: message.content }
        }.merge(tag_params)
        reply_id = message.external_reply_to_id
        payload[:recipient][:reply_to] = { mid: reply_id } if reply_id.present?
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
        }.merge(tag_params)
      end

      def tag_params
        human_agent_eligible? ? { tag: "HUMAN_AGENT" } : {}
      end

      def human_agent_eligible?
        return false unless human_agent_sender?
        return false unless outside_24_hours?
        return false if outside_7_days?

        true
      end

      def tag_error?(error)
        return false unless error.is_a?(Hash)

        code = error["code"].to_i
        msg = error["message"].to_s
        code == 230 || code == 100 || msg.include?("human_agent")
      end

      def attachment_type(attachment)
        return attachment.attachment_type if %w[image audio video file].include?(attachment.attachment_type)
        "file"
      end

      def log_error(result)
        error = result["error"] || {}
        error_code = error["code"].to_i
        error_message = error["message"] || "Unknown Instagram API error"

        message.update!(
          status: :failed,
          data: (message.data || {}).merge(
            "error_code" => error_code,
            "error_message" => error_message
          )
        )

        Rails.logger.error("Instagram send error for #{instagram_channel.instagram_id}: #{error}")

        if error_code == 190 || error_message.to_s.include?("The session has been invalidated") || error_message.to_s.include?("Error validating access token")
          instagram_channel.authorization_error!
        end
      end

      def log_exception(error)
        message.update!(
          status: :failed,
          data: (message.data || {}).merge("error_message" => error.message)
        )

        Rails.logger.error("Instagram send exception for #{instagram_channel.instagram_id}: #{error.message}")

        if error.to_s.include?("The session has been invalidated") || error.to_s.include?("Error validating access token")
          instagram_channel.authorization_error!
        end
      end

      def transient_error?(response_code, error_code)
        [429, 500, 502, 503, 504].include?(response_code) || [4, 17, 341].include?(error_code)
      end

      def transient_network_error?(error)
        error.message.to_s.include?("transient error") ||
          error.is_a?(Net::OpenTimeout) ||
          error.is_a?(Net::ReadTimeout) ||
          error.is_a?(Errno::ECONNRESET) ||
          error.is_a?(Errno::ECONNREFUSED) ||
          error.is_a?(SocketError)
      end
    end
  end
end
