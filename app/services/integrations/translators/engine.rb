# frozen_string_literal: true

module Integrations
  module Translators
    class Engine < ApplicationService
      attr_reader :message, :target_locale, :account

      def initialize(message:, target_locale:)
        @message = message
        @target_locale = target_locale
        @account = message.account
      end

      def call
        return unless message.content.present?

        existing_translations = message.data["translation"] || {}
        return existing_translations[target_locale] if existing_translations.key?(target_locale)

        translated_text = process_translation

        return unless translated_text.present?

        existing_translations[target_locale] = translated_text
        message.update!(data: message.data.merge("translation" => existing_translations))

        translated_text
      rescue StandardError => e
        Rails.logger.error("Translation Engine Failed dynamically: #{e.message}")
        nil
      end

      private

      def process_translation
        # Prefer google APIs if integration exists 
        google_integration = account.integrations.find_by(provider: :google_translate, active: true)

        if google_integration
          api_key = google_integration.settings["api_key"]
          return perform_google_translation(api_key) if api_key.present?
        end

        # Fallback to our translation engine 
        perform_libre_translation
      end

      def perform_google_translation(api_key)
        response = HTTParty.post(
          "https://translation.googleapis.com/language/translate/v2",
          body: {
            q: message.content,
            target: target_locale,
            key: api_key
          }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        )

        return nil unless response.success?
        response.parsed_response.dig("data", "translations", 0, "translatedText")
      end

      def perform_libre_translation
        url = ENV.fetch("OS_TRANSLATOR_URL", "http://localhost:5000/translate")
        
        response = HTTParty.post(
          url,
          body: {
            q: message.content,
            target: target_locale
          }.to_json,
          headers: { "Content-Type" => "application/json" },
          timeout: 5
        )

        return nil unless response.success?
        response.parsed_response["translatedText"]
      end
    end
  end
end
