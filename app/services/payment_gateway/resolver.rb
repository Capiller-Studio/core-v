# frozen_string_literal: true

module PaymentGateway
  class Resolver
    def self.for(account)
      provider = account.billing_data["provider"] || default_provider
      gateway_class(provider).new(account)
    end

    def self.gateway_class(provider)
      case provider.to_s
      when "stripe" then PaymentGateway::Stripe
      when "paddle" then PaymentGateway::Paddle
      else
        raise ArgumentError, "Unknown payment provider: #{provider}"
      end
    end

    def self.default_provider
      Rails.application.credentials.dig(:payment, :default_provider) || "paddle"
    end
  end
end
