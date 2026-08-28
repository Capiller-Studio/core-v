# frozen_string_literal: true

module Integrations
  module LanguageDetectors
    class Engine < ApplicationService
      attr_reader :text, :account
      attr_accessor :clean_text

      def initialize(text:, account:)
        @text = text
        @account = account
      end

      def call
        return if text.blank?
        
        # Strip HTML tags before detection so English tags like <p> or <div> don't skew the results
        self.clean_text = ActionController::Base.helpers.strip_tags(text)&.strip
        return if clean_text.blank? || clean_text.length < 5

        process_detection
      rescue StandardError => e
        Rails.logger.error("Language Detection Engine Failed dynamically: #{e.message}")
        nil
      end

      private

      def process_detection
        # Prefer google APIs if integration exists
        google_integration = account.integrations.find_by(provider: :google_translate, status: :active)

        if google_integration
          api_key = google_integration.credentials["api_key"]
          return perform_google_detection(api_key) if api_key.present?
        end

        # Fallback to our detection engine
        perform_libre_detection
      end

      def perform_google_detection(api_key)
        response = HTTParty.post(
          "https://translation.googleapis.com/language/translate/v2/detect",
          body: {
            q: clean_text,
            key: api_key
          }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        )

        return nil unless response.success?
        
        detections = response.parsed_response.dig("data", "detections", 0)
        return nil if detections.blank?
        
        detection = detections.first
        return nil unless detection && detection["language"] && detection["confidence"].to_f > 0.6
        
        detection["language"]
      end

      def perform_libre_detection
        base_url = ENV.fetch("OS_TRANSLATOR_URL", "http://localhost:5001/translate")
        
        begin
          uri = URI.parse(base_url)
          uri.path = "/detect"
          url = uri.to_s
        rescue URI::InvalidURIError
          url = "http://localhost:5001/detect"
        end

        response = HTTParty.post(
          url,
          body: { q: clean_text }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        )

        unless response.success?
          Rails.logger.error("LibreTranslate Detection Error: #{response.code} - #{response.body}")
          return nil
        end
        
        detected = response.parsed_response.first
        return nil unless detected && detected["language"] && detected["confidence"].to_f > 0.6
        
        detected["language"]
      end
    end
  end
end
