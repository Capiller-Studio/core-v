# frozen_string_literal: true

module Billing
  # Handles adding/removing payment methods for both Stripe and Paddle
  class PaymentMethodManager < ApplicationService
    attr_accessor :account

    def initialize(account:)
      self.account = account
    end

    # Add a payment method via token (Stripe)
    # Paddle handles this via checkout — see handle_paddle_payment_method
    def add_stripe_method(payment_method_token)
      gateway = PaymentGateway::Stripe.new(account)

      ActiveRecord::Base.transaction do
        result = gateway.add_payment_method(payment_method_token)

        is_first = account.payment_methods.active_methods.empty?

        PaymentMethod.create!(
          account:,
          provider: :stripe,
          payment_type: :card,
          status: :active,
          is_default: is_first,
          last_four: result[:last_four],
          brand: result[:brand],
          expiry_month: result[:expiry_month],
          expiry_year: result[:expiry_year],
          external_id: result[:external_id]
        )
      end
    end

    # When Paddle checkout completes, it sends payment method info via webhook
    def handle_paddle_payment_method(webhook_data)
      ActiveRecord::Base.transaction do
        payment_info = webhook_data.dig("data", "payment", "method_details")
        return unless payment_info

        is_first = account.payment_methods.active_methods.empty?

        PaymentMethod.create!(
          account:,
          provider: :paddle,
          payment_type: resolve_paddle_type(payment_info["type"]),
          status: :active,
          is_default: is_first,
          last_four: payment_info.dig("card", "last4"),
          brand: payment_info.dig("card", "type"),
          expiry_month: payment_info.dig("card", "expiry_month"),
          expiry_year: payment_info.dig("card", "expiry_year"),
          external_id: webhook_data.dig("data", "id"),
          data: payment_info
        )
      end
    end

    def remove_method(payment_method)
      ActiveRecord::Base.transaction do
        case payment_method.provider
        when "stripe"
          PaymentGateway::Stripe.new(account).remove_payment_method(payment_method.external_id)
        end

        payment_method.update!(status: :removed)

        # Promote next method to default if this was default
        if payment_method.is_default
          next_method = account.payment_methods.active_methods.first
          next_method&.update!(is_default: true)
        end
      end
    end

    def set_default(payment_method)
      payment_method.make_default!
    end

    private

    def resolve_paddle_type(type)
      case type
      when "paypal" then :paypal
      else :card
      end
    end
  end
end
