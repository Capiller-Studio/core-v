# frozen_string_literal: true

module Webhooks
  class StripeController < Webhooks::BaseController
    before_action :verify_stripe_signature

    def create
      return head(:bad_request) unless @event

      webhook = store_incoming_webhook(source: "stripe", payload: @event.to_h)
      Webhooks::StripeEventListenWorker.perform_async(webhook.id)

      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Stripe webhook error: #{e.message}")
      head(:bad_request)
    end

    private

    def verify_stripe_signature
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      endpoint_secret = Rails.application.credentials.dig(Rails.env.to_sym, :stripe, :webhook_secret).presence ||
                        Rails.application.credentials.dig(:stripe, :webhook_secret).presence ||
                        ENV["STRIPE_WEBHOOK_SECRET"]

      begin
        @event = ::Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
      rescue JSON::ParserError
        head(:bad_request)
      rescue ::Stripe::SignatureVerificationError
        head(:unauthorized)
      end
    end
  end
end
