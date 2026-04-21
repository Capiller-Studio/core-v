# frozen_string_literal: true

module Affiliates
  class CurrencyConverter < ApplicationService
    attr_reader :from_currency, :to_currency

    SPREAD_MARGIN = 0.025 # 2.5% platform conversion fee protecting margins natively

    def initialize(from_currency:, to_currency:)
      @from_currency = from_currency.upcase
      @to_currency = to_currency.upcase
    end

    def call
      return 1.0 if from_currency == to_currency

      base_rate = fetch_live_rate
      return 1.0 unless base_rate

      # Add spread to move things in our favor natively 
      (base_rate * (1.0 - SPREAD_MARGIN)).round(6)
    end

    private

    def fetch_live_rate
      # Pull securely synced matrix natively decoupled avoiding API lock limits!
      rate_record = ::ExchangeRate.find_by(from_currency: from_currency, to_currency: to_currency)
      rate_record&.rate
    end
  end
end
