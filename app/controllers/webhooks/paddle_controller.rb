# frozen_string_literal: true

module Webhooks
  class PaddleController < Webhooks::BaseController
    before_action :verify_paddle_signature

    def create
      webhook = store_incoming_webhook(source: "paddle", payload: params.to_unsafe_h)
      Webhooks::PaddleEventListenWorker.perform_async(webhook.id)

      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Paddle webhook error: #{e.message}")
      head(:bad_request)
    end

    private

    def verify_paddle_signature
      # Paddle signs webhooks with a shared secret
      webhook_secret = Rails.application.credentials.dig(:paddle, :webhook_secret)
      return head(:unauthorized) unless webhook_secret

      signature = request.headers["Paddle-Signature"]
      return head(:unauthorized) unless signature

      # Parse ts and h1 from "ts=...;h1=..."
      parts = signature.split(";").to_h { |p| p.split("=", 2) }
      ts = parts["ts"]
      h1 = parts["h1"]

      payload = "#{ts}:#{request.raw_post}"
      computed = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, payload)

      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(computed, h1)
    end
  end
end
