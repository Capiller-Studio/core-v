# frozen_string_literal: true

module Integrations
  module Slack
    class NotifierWorker
      include Sidekiq::Worker
      sidekiq_options retry: 3, queue: "default"

      def perform(webhook_url, event_name, payload_json)
        payload = JSON.parse(payload_json)

        # Build structurally formatted Slack layouts dynamically
        slack_body = case event_name
        when "message.created"
          build_message_created_block(payload)
        else
          { text: "System Event Triggered: #{event_name}" }
        end

        HTTParty.post(
          webhook_url,
          body: slack_body.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        )
      rescue StandardError => e
        Rails.logger.error("Slack Notification Engine Failed: #{e.message}")
      end

      private

      def build_message_created_block(payload)
        preview_text = payload["content"].to_s.truncate(100)
        source = payload["source"] || "Unknown Channel"

        {
          blocks: [
            {
              type: "header",
              text: {
                type: "plain_text",
                text: "New Message Received 🚨",
                emoji: true
              }
            },
            {
              type: "section",
              text: {
                type: "mrkdwn",
                text: "*Source:* #{source.capitalize}\n*Content:* #{preview_text}"
              }
            }
          ]
        }
      end
    end
  end
end
