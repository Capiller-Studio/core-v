# frozen_string_literal: true

module Automations
  module Actions
    class TriggerWebhook < BaseAction
      def call
        url = params[:url]
        method = params.fetch(:method, "POST").upcase
        headers = params.fetch(:headers, {})
        secret = params[:secret] # Optional: HMAC signing key for request verification

        raise("url is required") if url.blank?
        raise("Invalid method: #{method}") unless %w[GET POST PUT PATCH].include?(method)

        # Build the payload with conversation/customer context
        webhook_payload = {
          event: "automation.triggered",
          resource_type: resource.class.name,
          resource_id: resource.id,
          account_id: account.id,
          data: resource.respond_to?(:event_payload) ? resource.event_payload : { id: resource.id },
          triggered_at: Time.current.iso8601
        }

        # Enqueue async HTTP delivery to avoid blocking the action chain
        Automations::WebhookDeliveryWorker.perform_async(
          url,
          method,
          headers.to_json,
          webhook_payload.to_json,
          secret
        )
      end
    end
  end
end
