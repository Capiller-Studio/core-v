# frozen_string_literal: true

module PaymentGateway
  class Base
    attr_reader :account

    def initialize(account)
      @account = account
    end

    # Customer management
    def create_customer
      raise(NotImplementedError)
    end

    def retrieve_customer(external_id)
      raise(NotImplementedError)
    end

    # Payment methods
    def add_payment_method(token)
      raise(NotImplementedError)
    end

    def remove_payment_method(external_id)
      raise(NotImplementedError)
    end

    def list_payment_methods
      raise(NotImplementedError)
    end

    # Charges
    def charge(amount:, currency:, description: nil, payment_method_id: nil)
      raise(NotImplementedError)
    end

    def refund(transaction_external_id:, amount: nil)
      raise(NotImplementedError)
    end

    # Subscriptions (for gateways that support managed subscriptions)
    def create_subscription(plan:, billing_cycle:, payment_method_id: nil)
      raise(NotImplementedError)
    end

    def cancel_subscription(external_id)
      raise(NotImplementedError)
    end

    def retrieve_subscription(external_id)
      raise(NotImplementedError)
    end

    # Provider name
    def provider_name
      raise(NotImplementedError)
    end

    protected

    def gateway_customer_id
      account.billing_data["#{provider_name}_customer_id"]
    end

    def store_customer_id(external_id)
      account.update!(
        billing_data: account.billing_data.merge("#{provider_name}_customer_id" => external_id)
      )
    end
  end
end
