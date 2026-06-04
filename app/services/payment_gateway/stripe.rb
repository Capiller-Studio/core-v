# frozen_string_literal: true

require "stripe"
module PaymentGateway
  class Stripe < Base
    def create_customer
      customer = ::Stripe::Customer.create(
        email: account.email,
        name: account.name,
        metadata: { account_id: account.id }
      )
      store_customer_id(customer.id)
      customer
    end

    def create_setup_intent
      customer_id = gateway_customer_id || create_customer.id
      ::Stripe::SetupIntent.create(customer: customer_id)
    end

    def retrieve_customer(external_id = nil)
      ::Stripe::Customer.retrieve(external_id || gateway_customer_id)
    end

    def add_payment_method(token)
      customer_id = gateway_customer_id || create_customer.id

      pm = ::Stripe::PaymentMethod.attach(token, customer: customer_id)

      # Set as default if first method
      ::Stripe::Customer.update(customer_id, invoice_settings: { default_payment_method: pm.id })

      {
        external_id: pm.id,
        brand: pm.card&.brand,
        last_four: pm.card&.last4,
        expiry_month: pm.card&.exp_month,
        expiry_year: pm.card&.exp_year
      }
    end

    def remove_payment_method(external_id)
      ::Stripe::PaymentMethod.detach(external_id)
    end

    def charge(amount:, currency:, description: nil, payment_method_id: nil)
      customer_id = gateway_customer_id
      return nil unless customer_id

      intent = ::Stripe::PaymentIntent.create(
        amount: (amount * 100).to_i, # Stripe uses cents
        currency: currency.downcase,
        customer: customer_id,
        payment_method: payment_method_id,
        description:,
        confirm: true,
        off_session: true,
        metadata: { account_id: account.id }
      )

      {
        external_id: intent.id,
        status: intent.status == "succeeded" ? :completed : :pending,
        amount: amount
      }
    rescue ::Stripe::CardError => e
      { external_id: nil, status: :failed, error: e.message }
    end

    def refund(transaction_external_id:, amount: nil)
      params = { payment_intent: transaction_external_id }
      params[:amount] = (amount * 100).to_i if amount

      r = ::Stripe::Refund.create(params)
      { external_id: r.id, status: :completed }
    end

    def provider_name
      "stripe"
    end
  end
end
