# frozen_string_literal: true

module Webhooks
  class InstagramController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false

    # GET /webhooks/instagram
    def hub
      verify_token = Rails.application.credentials.dig(:channels, :instagram, :verify_token)
      if params["hub.verify_token"] == verify_token
        render(plain: params["hub.challenge"])
      else
        render(plain: "Error, wrong validation token", status: :forbidden)
      end
    end

    # POST /webhooks/instagram
    def index
      # Enqueue job to handle the incoming webhook event
      Webhooks::InstagramEventListenWorker.perform_async(params.to_unsafe_h)
      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Instagram webhook processing error: #{e.message}")
      head(:internal_server_error)
    end
  end
end
