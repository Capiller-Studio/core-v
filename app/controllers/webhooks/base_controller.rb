# frozen_string_literal: true

module Webhooks
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false

    protected

    def store_incoming_webhook(source:, payload:, event_type: nil)
      Webhook::Incoming.create!(
        source: source,
        event_type: event_type,
        request_url: request.original_url,
        headers: safe_headers,
        payload: payload,
        status: :pending
      )
    end

    def safe_headers
      request.headers.to_h.select { |k, _v| k.start_with?("HTTP_") || k == "CONTENT_TYPE" }
    end
  end
end
