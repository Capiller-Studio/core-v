# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.2.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class MessageSender < ApplicationService
        include Channels::Concerns::MetaWindowPolicy

        attr_accessor :whatsapp_channel, :customer_inbox, :message

        def initialize(whatsapp_channel:, customer_inbox:, message:)
          self.whatsapp_channel = whatsapp_channel
          self.customer_inbox   = customer_inbox
          self.message          = message
        end

        def call
          if recipient_phone_number.blank?
            handle_missing_recipient
            return
          end

          if template_requested? || (outside_24_hours? && template_available?)
            send_template_message
          else
            send_standard_messages
          end
        rescue StandardError => e
          raise(e) if transient_exception?(e)

          log_exception(e)
        end

        private

        def recipient_phone_number
          raw = customer_inbox.customer&.full_phone_number.presence || customer_inbox.external_id.presence || customer_inbox.customer&.external_id
          digits = raw.to_s.gsub(/\D/, "")
          digits.presence || raw.to_s.strip
        end

        def handle_missing_recipient
          Rails.logger.warn("WhatsApp MessageSender: Recipient phone number is missing for message #{message.id}")
          message.update!(
            status: :failed,
            data: (message.data || {}).merge("error_message" => "Recipient phone number is missing")
          )
        end

        def send_standard_messages
          if message.attachments.blank?
            send_text_message if message.content.present?
          elsif single_captionable_attachment?
            send_attachment_message(message.attachments.first, caption: message.content)
          else
            send_text_message if message.content.present?
            message.attachments.each { |attachment| send_attachment_message(attachment) }
          end
        end

        def single_captionable_attachment?
          return false unless message.attachments.one?

          attachment_type = resolved_attachment_type(message.attachments.first)
          %w[image video document].include?(attachment_type)
        end

        def send_text_message
          response = HTTParty.post(
            "#{whatsapp_channel.phone_number_endpoint}/messages",
            headers: whatsapp_channel.api_headers,
            body: {
              messaging_product: "whatsapp",
              context: message_context,
              to: recipient_phone_number,
              text: { body: Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) },
              type: "text"
            }.to_json
          )

          process_response(response)
        end

        def send_attachment_message(attachment, caption: nil)
          attachment_type = resolved_attachment_type(attachment)
          url = attachment.direct_download_url

          if url.blank?
            Rails.logger.warn("WhatsApp MessageSender: Attachment #{attachment.id} has no direct_download_url")
            message.update!(
              status: :failed,
              data: (message.data || {}).merge("error_message" => "Attachment file URL is missing")
            )
            return
          end

          attachment_content = { link: url }
          if caption.present? && %w[image video document].include?(attachment_type)
            attachment_content["caption"] = Channels::MessageFormatter.format_for_whatsapp_and_facebook(caption)
          end
          if attachment_type == "document" && attachment.file.present?
            filename = attachment.file&.filename&.to_s
            attachment_content["filename"] = filename if filename.present?
          end

          response = HTTParty.post(
            "#{whatsapp_channel.phone_number_endpoint}/messages",
            headers: whatsapp_channel.api_headers,
            body: {
              messaging_product: "whatsapp",
              context: message_context,
              to: recipient_phone_number,
              type: attachment_type,
              attachment_type => attachment_content
            }.to_json
          )

          process_response(response)
        end

        def send_template_message
          payload = {
            messaging_product: "whatsapp",
            to: recipient_phone_number,
            type: "template",
            template: {
              name: resolved_template_name,
              language: { code: resolved_template_language }
            }
          }

          components = template_components
          payload[:template][:components] = components if components.present?

          response = HTTParty.post(
            "#{whatsapp_channel.phone_number_endpoint}/messages",
            headers: whatsapp_channel.api_headers,
            body: payload.to_json
          )

          process_response(response)
        end

        def template_components
          if message.data["template_components"].present?
            return message.data["template_components"]
          end

          components = []

          # Meta templates accept at most one media header component (IMAGE, VIDEO, or DOCUMENT)
          if message.attachments.present?
            attachment = message.attachments.first
            header_type = resolved_attachment_type(attachment)

            if %w[image video document].include?(header_type) && attachment.direct_download_url.present?
              components << {
                type: "header",
                parameters: [
                  {
                    type: header_type,
                    header_type => { link: attachment.direct_download_url }
                  }
                ]
              }
            end
          end

          body_params = template_body_params
          components << { type: "body", parameters: body_params } if body_params.present?
          components
        end

        def template_body_params
          custom_params = message.data["template_parameters"]
          if custom_params.is_a?(Array)
            custom_params.map do |param|
              if param.is_a?(Hash)
                param.key?(:type) || param.key?("type") ? param : { type: "text", text: (param["text"] || param[:text]).to_s }
              else
                { type: "text", text: param.to_s }
              end
            end
          elsif message.content.present?
            [{ type: "text", text: Channels::MessageFormatter.format_for_whatsapp_and_facebook(message.content) }]
          else
            []
          end
        end

        def process_response(response)
          parsed = response.parsed_response
          is_hash = parsed.is_a?(Hash)

          if response.success? && is_hash
            wamid = parsed.dig("messages", 0, "id")
            message.update!(external_id: wamid) if wamid.present?
          else
            whatsapp_channel.authorization_error! if response.unauthorized?

            error_data = is_hash && (parsed["error"].is_a?(Hash) || parsed[:error].is_a?(Hash)) ? (parsed["error"] || parsed[:error]) : {}
            error_code = error_data["code"] || error_data[:code]
            error_message = error_data["message"] || error_data[:message] || (parsed.is_a?(String) ? parsed : "WhatsApp message delivery failed")

            # Auto-retry with approved template if 24h window error 131047 occurs
            if error_code == 131047 && template_available? && !@retried_with_template
              @retried_with_template = true
              return send_template_message
            end

            # Auto-retry with default language if language mismatch error 132000 occurs
            if error_code == 132000 && !@retried_with_fallback_lang
              @retried_with_fallback_lang = true
              @fallback_language = whatsapp_channel.template_language
              return send_template_message
            end

            if transient_meta_error?(response, error_code)
              Rails.logger.warn("WhatsApp transient error (#{response.code}/#{error_code}) for #{recipient_phone_number}, raising for Sidekiq retry")
              raise("Meta WhatsApp API transient error (#{response.code}): #{error_message}")
            end

            message.update!(
              status: :failed,
              data: (message.data || {}).merge(
                "error_code" => error_code,
                "error_message" => error_message
              )
            )

            if error_code == 131047
              Rails.logger.warn("WhatsApp 24-hour customer service window closed for #{recipient_phone_number} (Error 131047). Configure an approved template in channel settings to bypass the 24-hour window.")
            else
              Rails.logger.error("WhatsApp Message Sender Error: #{parsed}")
            end
          end
        end

        def resolved_template_name
          message.data["template_name"].presence ||
            whatsapp_channel.template_name.presence ||
            ENV.fetch("WHATSAPP_DEFAULT_TEMPLATE_NAME", nil)
        end

        def resolved_template_language
          return @fallback_language if defined?(@fallback_language) && @fallback_language.present?

          raw_lang = message.data["template_language"].presence ||
                     message.conversation&.locale.presence ||
                     whatsapp_channel.template_language

          normalize_meta_locale(raw_lang)
        end

        def normalize_meta_locale(locale)
          return "en_US" if locale.blank?

          cleaned = locale.to_s.strip.tr("-", "_")
          case cleaned.downcase
          when "en" then "en_US"
          when "pt" then "pt_BR"
          when "es" then "es"
          when "zh" then "zh_CN"
          else
            parts = cleaned.split("_")
            if parts.size >= 2
              "#{parts[0].downcase}_#{parts[1].upcase}"
            else
              parts[0].downcase
            end
          end
        end

        def resolved_attachment_type(attachment)
          case attachment.attachment_type.to_s
          when "image" then "image"
          when "audio" then "audio"
          when "video" then "video"
          else "document"
          end
        end

        def template_available?
          resolved_template_name.present?
        end

        def template_requested?
          message.data["type"] == "template" || message.data["template_name"].present?
        end

        def transient_meta_error?(response, error_code)
          http_code = response.code.to_i
          return true if http_code == 429 || (500..504).cover?(http_code)
          return true if [1, 2, 4, 130429].include?(error_code)

          false
        end

        def transient_exception?(error)
          error.message.include?("Meta WhatsApp API transient error") ||
            error.is_a?(Net::OpenTimeout) ||
            error.is_a?(Net::ReadTimeout) ||
            error.is_a?(Errno::ECONNRESET)
        end

        def log_exception(error)
          message.update!(
            status: :failed,
            data: (message.data || {}).merge("error_message" => error.message)
          )
          Rails.logger.error("WhatsApp MessageSender exception for #{whatsapp_channel.phone_number_id}: #{error.message}")

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
