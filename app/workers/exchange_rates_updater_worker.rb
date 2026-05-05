# frozen_string_literal: true

class ExchangeRatesUpdaterWorker
  include Sidekiq::Worker

  SUPPORTED_CURRENCIES = %w[USD EUR GBP].freeze

  # Runs hourly caching API endpoints accurately inside the db
  def perform
    base = "USD"
    # Fallback free-tier er-api (Provides rates relative to USD fundamentally)
    response = HTTParty.get("https://open.er-api.com/v6/latest/#{base}")
    return unless response.success?

    rates = response.parsed_response["rates"]
    return unless rates

    ActiveRecord::Base.transaction do
      SUPPORTED_CURRENCIES.each do |from_currency|
        SUPPORTED_CURRENCIES.each do |to_currency|
          next if from_currency == to_currency

          # Compute cross-rates mathematically organically using USD bases
          # Cross rate A -> B = (USD -> B) / (USD -> A)
          rate_to_a = rates[from_currency].to_f
          rate_to_b = rates[to_currency].to_f

          next if rate_to_a.zero? || rate_to_b.zero?

          cross_rate = (rate_to_b / rate_to_a).round(6)

          record = ExchangeRate.find_or_initialize_by(from_currency: from_currency, to_currency: to_currency)
          record.update!(rate: cross_rate)
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error("Exchange Rate Sync Failed: #{e.message}")
  end
end
