# frozen_string_literal: true

module Webhook
  class Incoming < ApplicationRecord
    enum :status, { pending: 0, processed: 1, failed: 2, permanently_failed: 3 }

    validates :source, presence: true
    validates :payload, presence: true

    # Extracts named route parameters (e.g. :account_id, :channel_id) from the stored
    # request_url using the Rails router. Workers use this to recover routing context
    def route_params
      return {} if request_url.blank?

      uri = URI.parse(request_url)
      Rails.application.routes.recognize_path(uri.path, method: :post)
    rescue ActionController::RoutingError, URI::InvalidURIError
      {}
    end

    # Extracts query string parameters from the stored request_url using Rack.
    def query_params
      return {} if request_url.blank?

      uri = URI.parse(request_url)
      Rack::Utils.parse_nested_query(uri.query || "")
    rescue URI::InvalidURIError
      {}
    end
  end
end
