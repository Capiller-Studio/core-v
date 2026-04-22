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

        integration = delivery.integration
        return unless integration&.active? && integration.webhook?

        begin
          response = HTTParty.post(
            delivery.endpoint_url,
            body: delivery.request_payload.to_json,
            headers: {
              "Content-Type" => "application/json",
              "User-Agent" => "Deskbolic-Webhook-Engine/1.0"
            },
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
