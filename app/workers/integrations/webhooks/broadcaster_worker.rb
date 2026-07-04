# frozen_string_literal: true

module Integrations
  module Webhooks
    class BroadcasterWorker
      include Sidekiq::Worker
      sidekiq_options retry: 3, queue: "default"

      def perform(delivery_id, attempt_number = 1)
        delivery = WebhookDelivery.find_by(id: delivery_id)
        return unless delivery

        # Guard against duplicate dispatches
        return if delivery.successful?

        resource = delivery.resource
        return unless resource

        if resource.is_a?(Integration)
          return unless resource.active? && resource.webhook?
        elsif resource.is_a?(Channel::Custom)
          return unless resource.active?
        end

        begin
          body = delivery.request_payload.to_json
          timestamp = Time.now.to_i
          secret = resource.is_a?(Channel::Custom) ? resource.hmac_token : resource.webhook_secret

          headers = {
            "Content-Type" => "application/json",
            "User-Agent" => "Deskbolic-Webhook-Engine/1.0"
          }

          # Add HMAC-SHA256 signature if the integration has a webhook secret configured.
          # Format: "t=<timestamp>,v1=<hex_digest>"
          # Receiver verifies by recomputing: HMAC-SHA256(secret, "<timestamp>-<body>")
          if secret.present?
            signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}-#{body}")
            headers["Signature"] = "t=#{timestamp},v1=#{signature}"
          end

          response = HTTParty.post(
            delivery.endpoint_url,
            body: body,
            headers: headers,
            timeout: 10
          )

          handle_attempt(
            delivery: delivery,
            attempt_number: attempt_number,
            success: response.success?,
            http_status: response.code,
            response_body: response.body&.truncate(1000),
            error: response.success? ? nil : "Completed with HTTP #{response.code}"
          )
        rescue StandardError => e
          handle_attempt(
            delivery: delivery,
            attempt_number: attempt_number,
            success: false,
            error: e.message
          )
        end
      end

      private

      def handle_attempt(delivery:, attempt_number:, success:, http_status: nil, response_body: nil, error: nil)
        WebhookDeliveryAttempt.create!(
          delivery: delivery,
          attempt_number: attempt_number,
          http_status: http_status,
          response_body: response_body,
          error_trace: error
        )

        if success
          delivery.successful!
        elsif attempt_number < 3
          self.class.perform_in((attempt_number * 10).minutes, delivery.id, attempt_number + 1)
        else
          delivery.failed!
        end
      end
    end
  end
end
