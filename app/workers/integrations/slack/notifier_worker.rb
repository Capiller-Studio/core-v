# frozen_string_literal: true

module Integrations
  module Slack
    class NotifierWorker
      include Sidekiq::Worker
      sidekiq_options retry: 3, queue: "default"

      def perform(account_id, delivery_id, attempt_number = 1)
        account = Account.find_by(id: account_id)
        return unless account

        account.with_shard do
          delivery = Webhook::Delivery.find_by(id: delivery_id)
          return unless delivery

          # Guard against duplicate dispatches
          return if delivery.successful?

          resource = delivery.resource
          return unless resource && resource.is_a?(Integration) && resource.active? && resource.slack?

          payload = delivery.request_payload

          # Don't notify Slack for outgoing agent replies or internal notes to avoid noise
          if delivery.event_name == "message.created"
            incoming_message = if payload.key?("incoming")
              payload["incoming"] == true
            else
              payload["message_type"] == "incoming"
            end

            unless incoming_message
              delivery.successful!
              return
            end
          end

          target_locale = account.locale.presence || payload.dig("account", "locale") || I18n.default_locale

          begin
            slack_body = I18n.with_locale(target_locale) do
              case delivery.event_name
              when "message.created"
                build_message_created_block(payload)
              when "conversation.created"
                build_conversation_created_block(account, payload)
              else
                build_event_notification(delivery.event_name)
              end
            end

            response = HTTParty.post(
              delivery.endpoint_url,
              body: slack_body.to_json,
              headers: { "Content-Type" => "application/json" },
              timeout: 10
            )

            handle_attempt(
              account_id: account.id,
              delivery: delivery,
              attempt_number: attempt_number,
              success: response.success?,
              http_status: response.code,
              response_body: response.body&.truncate(1000),
              error: response.success? ? nil : "Completed with HTTP #{response.code}: #{response.body}"
            )
          rescue StandardError => e
            handle_attempt(
              account_id: account.id,
              delivery: delivery,
              attempt_number: attempt_number,
              success: false,
              error: e.message
            )
          end
        end
      end

      private

      def handle_attempt(account_id:, delivery:, attempt_number:, success:, http_status: nil, response_body: nil, error: nil)
        Webhook::DeliveryAttempt.create!(
          delivery: delivery,
          attempt_number: attempt_number,
          http_status: http_status,
          response_body: response_body,
          error_trace: error
        )

        if success
          delivery.successful!
        elsif attempt_number < 3
          self.class.perform_in((attempt_number * 5).minutes, account_id, delivery.id, attempt_number + 1)
        else
          delivery.failed!
        end
      end

      def build_message_created_block(payload)
        preview_text = ActionController::Base.helpers.strip_tags(payload["content"].to_s)&.truncate(200)
        preview_text = I18n.t("notifications.slack.attachment_preview", default: "*(Attachment / Media)*") if preview_text.blank?

        default_customer = I18n.t("notifications.slack.default_customer", default: "Customer")
        sender_name = payload.dig("sender", "name").presence || payload.dig("sender", "email").presence || default_customer
        conversation_id = payload.dig("conversation", "id")
        channel_type = payload.dig("conversation", "channel_type") || payload["source"] || I18n.t("notifications.slack.default_channel", default: "Channel")
        channel_icon = channel_emoji(channel_type)
        safe_sender_name = escape_slack_text(sender_name)
        safe_channel_type = escape_slack_text(channel_type.to_s.titleize)
        safe_preview_text = escape_slack_text(preview_text)

        blocks = [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: I18n.t("notifications.slack.new_message_header", icon: channel_icon, default: "#{channel_icon} New Customer Message"),
              emoji: true
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: I18n.t("notifications.slack.from_field", sender: safe_sender_name, default: "*From:*\n#{safe_sender_name}")
              },
              {
                type: "mrkdwn",
                text: I18n.t("notifications.slack.channel_field", channel: safe_channel_type, default: "*Channel:*\n#{safe_channel_type}")
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: I18n.t("notifications.slack.message_field", message: safe_preview_text, default: "*Message:*\n#{safe_preview_text}")
            }
          }
        ]

        if conversation_id.present?
          conversation_url = build_conversation_url(payload, conversation_id)
          if conversation_url.present?
            blocks << {
              type: "actions",
              elements: [
                {
                  type: "button",
                  text: {
                    type: "plain_text",
                    text: I18n.t("notifications.slack.open_button", default: "Open in Deskbolic ↗"),
                    emoji: true
                  },
                  url: conversation_url,
                  style: "primary"
                }
              ]
            }
          end
        end

        fallback_text = I18n.t(
          "notifications.slack.message_fallback",
          sender: safe_sender_name,
          message: safe_preview_text,
          default: "#{channel_icon} New customer message from #{safe_sender_name}: #{safe_preview_text}"
        )

        { text: fallback_text, blocks: blocks }
      end

      def build_conversation_created_block(account, payload)
        payload = conversation_created_payload(account, payload)
        default_customer = I18n.t("notifications.slack.default_customer", default: "Customer")
        customer_name = payload.dig("customer", "name").presence || payload.dig("customer", "email").presence || default_customer
        conversation_id = payload["id"]
        channel_type = payload["channel_type"] || I18n.t("notifications.slack.default_support", default: "Support")
        channel_icon = channel_emoji(channel_type)
        preview_text = ActionController::Base.helpers.strip_tags(payload["last_message_preview"].to_s).presence || I18n.t("notifications.slack.default_conversation_preview", default: "A new customer conversation has been opened.")
        safe_customer_name = escape_slack_text(customer_name)
        safe_channel_type = escape_slack_text(channel_type.to_s.titleize)
        safe_preview_text = escape_slack_text(preview_text)

        blocks = [
          {
            type: "header",
            text: {
              type: "plain_text",
              text: I18n.t("notifications.slack.new_conversation_header", icon: channel_icon, default: "#{channel_icon} New Conversation Opened"),
              emoji: true
            }
          },
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: I18n.t("notifications.slack.customer_field", customer: safe_customer_name, default: "*Customer:*\n#{safe_customer_name}")
              },
              {
                type: "mrkdwn",
                text: I18n.t("notifications.slack.channel_field", channel: safe_channel_type, default: "*Channel:*\n#{safe_channel_type}")
              }
            ]
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: I18n.t("notifications.slack.initial_message_field", message: safe_preview_text, default: "*Initial Message:*\n#{safe_preview_text}")
            }
          }
        ]

        if conversation_id.present?
          conversation_url = build_conversation_url(payload, conversation_id)
          if conversation_url.present?
            blocks << {
              type: "actions",
              elements: [
                {
                  type: "button",
                  text: {
                    type: "plain_text",
                    text: I18n.t("notifications.slack.open_button", default: "Open in Deskbolic ↗"),
                    emoji: true
                  },
                  url: conversation_url,
                  style: "primary"
                }
              ]
            }
          end
        end

        fallback_text = I18n.t(
          "notifications.slack.conversation_fallback",
          customer: safe_customer_name,
          message: safe_preview_text,
          default: "#{channel_icon} New conversation from #{safe_customer_name}: #{safe_preview_text}"
        )

        { text: fallback_text, blocks: blocks }
      end

      def conversation_created_payload(account, payload)
        conversation = account.conversations.includes(:customers, :last_message).find_by(id: payload["id"])
        return payload unless conversation

        customer = conversation.customers.first
        payload.merge(
          "customer" => {
            "name" => customer&.name,
            "email" => customer&.email
          },
          "channel_type" => conversation.source,
          "last_message_preview" => conversation.last_message_preview,
          "account" => { "identifier" => account.identifier }
        )
      end

      def escape_slack_text(value)
        value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
      end

      def build_event_notification(event_name)
        event_label = event_name.to_s.tr(".", " ").humanize
        { text: "Deskbolic: #{escape_slack_text(event_label)}" }
      end

      def channel_emoji(channel_type)
        case channel_type.to_s.downcase
        when /whatsapp/ then "💬"
        when /email/ then "✉️"
        when /web_widget/, /widget/ then "🌐"
        when /instagram/ then "📸"
        when /facebook/ then "👥"
        when /contact_form/ then "📋"
        else "📬"
        end
      end

      def build_conversation_url(payload, conversation_id)
        base = ENV["DESKBOLIC_URL"].presence
        subdomain = payload.dig("account", "identifier")

        if base.present? && subdomain.present? && base.include?("://")
          uri = URI.parse(base)
          "#{uri.scheme}://#{subdomain}.#{uri.host}#{":#{uri.port}" if uri.port != 80 && uri.port != 443}/conversations/#{conversation_id}"
        elsif base.present?
          "#{base.chomp('/')}/conversations/#{conversation_id}"
        else
          "https://deskbolic.app/conversations/#{conversation_id}"
        end
      rescue StandardError
        nil
      end
    end
  end
end
