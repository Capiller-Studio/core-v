# frozen_string_literal: true

module Billing
  # Creates a Paddle checkout session for the client-side overlay
  # Returns a checkout URL / transaction_id that the frontend uses
  class CheckoutSessionCreator < ApplicationService
    attr_accessor :account, :plan, :billing_cycle

    def initialize(account:, plan:, billing_cycle: :monthly)
      self.account = account
      self.plan = plan
      self.billing_cycle = billing_cycle
    end

    def call
      gateway = PaymentGateway::Resolver.for(account)

      case gateway.provider_name
      when "paddle" then create_paddle_checkout(gateway)
      when "stripe" then create_stripe_checkout(gateway)
      end
    end

    private

    def create_paddle_checkout(gateway)
      customer_id = gateway.send(:gateway_customer_id) || gateway.create_customer["id"]
      price_id = plan.configurations.dig("paddle", "price_id_#{billing_cycle}")

      # Paddle uses client-side checkout — return data for frontend Paddle.js
      {
        provider: "paddle",
        customer_id:,
        items: [ { price_id:, quantity: account.account_users.count } ],
        custom_data: {
          account_id: account.id,
          plan_id: plan.id,
          billing_cycle:
        }
      }
    end

    def create_stripe_checkout(gateway)
      customer_id = gateway.send(:gateway_customer_id) || gateway.create_customer.id
      price_amount = (plan.price_for(billing_cycle) * 100).to_i # Stripe uses cents

      session = ::Stripe::Checkout::Session.create(
        customer: customer_id,
        mode: "subscription",
        line_items: [ {
          price_data: {
            currency: account.currency.downcase,
            product_data: { name: "Deskbolic #{plan.name.capitalize}" },
            unit_amount: price_amount,
            recurring: { interval: billing_cycle.to_s == "annual" ? "year" : "month" }
          },
          quantity: account.account_users.count
        } ],
        success_url: "#{base_url}/billing/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{base_url}/billing/cancel",
        metadata: {
          account_id: account.id,
          plan_id: plan.id,
          billing_cycle:
        }
      )

      {
        provider: "stripe",
        session_id: session.id,
        checkout_url: session.url
      }
    end

    def base_url
      Rails.application.credentials.dig(:app, :base_url) || "https://rely.capiller.com"
    end
  end
end
