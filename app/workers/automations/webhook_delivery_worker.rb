# frozen_string_literal: true

module Automations
  class WebhookDeliveryWorker
    include Sidekiq::Worker
    sidekiq_options queue: "automations", retry: 3

    # Delivers an HTTP webhook call triggered by the trigger_webhook automation action.
    #
    # @param url [String] target URL
    # @param method [String] HTTP method (GET, POST, PUT, PATCH)
    # @param headers_json [String] JSON-encoded hash of custom headers
    # @param payload_json [String] JSON-encoded request body
    # @param secret [String] optional HMAC secret for signing the request
    def perform(url, method, headers_json, payload_json, secret = nil)
      custom_headers = JSON.parse(headers_json)
      body = payload_json
      timestamp = Time.now.to_i

      headers = {
        "Content-Type" => "application/json",
        "User-Agent" => "Deskbolic-Automations/1.0"
      }.merge(custom_headers)

      # Add HMAC-SHA256 signature if a secret is provided.
      # Format: "t=<timestamp>,v1=<hex_digest>"
      # The receiver can verify by recomputing: HMAC-SHA256(secret, "<timestamp>-<body>")
      if secret.present?
        signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}-#{body}")
        headers["Deskbolic-Signature"] = "t=#{timestamp},v1=#{signature}"
      end

      response = case method.upcase
      when "GET"
                   HTTParty.get(url, headers: headers, timeout: 10)
      when "POST"
                   HTTParty.post(url, body: body, headers: headers, timeout: 10)
      when "PUT"
                   HTTParty.put(url, body: body, headers: headers, timeout: 10)
      when "PATCH"
                   HTTParty.patch(url, body: body, headers: headers, timeout: 10)
      end

      unless response&.success?
        Rails.logger.warn("[Automations::WebhookDeliveryWorker] #{method} #{url} returned #{response&.code}")
      end

    rescue StandardError => e
      Rails.logger.error("[Automations::WebhookDeliveryWorker] Request failed: #{e.message}")
      raise # Let Sidekiq retry
    end
  end
end
