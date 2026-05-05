# frozen_string_literal: true

module PaymentGateway
  class Paddle < Base
    # Paddle is a Merchant of Record — checkout and payment methods
    # are managed via Paddle.js on the client side + webhooks

    def create_customer
      response = paddle_client.post("/customers", {
        email: account.email,
        name: account.name,
        custom_data: { account_id: account.id }
      })
      store_customer_id(response["data"]["id"])
      response["data"]
    end

    def retrieve_customer(external_id = nil)
      paddle_client.get("/customers/#{external_id || gateway_customer_id}")
    end

    # Paddle collects payment methods during checkout overlay (Paddle.js)
    # After checkout, webhook delivers method details via PaddleController
    # See: Billing::PaymentMethodManager#handle_paddle_payment_method
    def add_payment_method(_token)
      # Return instructions — frontend should use Paddle.js checkout overlay
      {
        provider: "paddle",
        message: "Use Paddle.js overlay to collect payment method",
        customer_id: gateway_customer_id
      }
    end

    def remove_payment_method(_external_id)
      # Paddle manages payment methods — customer manages via Paddle portal
      { provider: "paddle", message: "Payment methods are managed via Paddle portal" }
    end

    def list_payment_methods
      return [] unless gateway_customer_id

      # Paddle doesn't expose stored payment methods via API
      # We rely on locally stored records from webhook data
      account.payment_methods.where(provider: :paddle).active_methods
    end

    def charge(amount:, currency:, description: nil, payment_method_id: nil)
      customer_id = gateway_customer_id
      return { external_id: nil, status: :failed, error: "No Paddle customer" } unless customer_id

      response = paddle_client.post("/transactions", {
        customer_id:,
        items: [ {
          price: {
            description: description || "Deskbolic charge",
            unit_price: { amount: (amount * 100).to_i.to_s, currency_code: currency.upcase },
            product_id: product_id
          },
          quantity: 1
        } ],
        custom_data: { account_id: account.id }
      })

      data = response["data"]
      {
        external_id: data["id"],
        status: data["status"] == "completed" ? :completed : :pending,
        amount:
      }
    rescue StandardError => e
      { external_id: nil, status: :failed, error: e.message }
    end

    def refund(transaction_external_id:, amount: nil)
      params = {
        transaction_id: transaction_external_id,
        action: "refund",
        reason: "Customer refund"
      }
      params[:amount] = (amount * 100).to_i.to_s if amount

      response = paddle_client.post("/adjustments", params)
      { external_id: response["data"]["id"], status: :completed }
    end

    def create_subscription(plan:, billing_cycle:, payment_method_id: nil)
      customer_id = gateway_customer_id || create_customer["id"]
      price_id = plan.configurations.dig("paddle", "price_id_#{billing_cycle}")

      response = paddle_client.post("/subscriptions", {
        customer_id:,
        items: [ { price_id:, quantity: account.account_users.count } ],
        custom_data: { account_id: account.id, plan_id: plan.id, billing_cycle: }
      })

      { external_id: response["data"]["id"], status: response["data"]["status"] }
    end

    def cancel_subscription(external_id)
      paddle_client.post("/subscriptions/#{external_id}/cancel", { effective_from: "next_billing_period" })
    end

    def retrieve_subscription(external_id)
      paddle_client.get("/subscriptions/#{external_id}")
    end

    def provider_name
      "paddle"
    end

    private

    def product_id
      Rails.application.credentials.dig(:paddle, :product_id)
    end

    def paddle_client
      @paddle_client ||= PaddleClient.new
    end
  end

  # Simple HTTP client for Paddle API v2
  class PaddleClient
    BASE_URL = "https://api.paddle.com"
    SANDBOX_URL = "https://sandbox-api.paddle.com"

    def initialize
      @api_key = Rails.application.credentials.dig(:paddle, :api_key)
      @base_url = Rails.env.production? ? BASE_URL : SANDBOX_URL
    end

    def get(path)
      response = HTTParty.get("#{@base_url}#{path}", headers: auth_headers)
      parsed = JSON.parse(response.body)
      raise("Paddle API error: #{parsed['error']}") if parsed["error"]

      parsed
    end

    def post(path, body)
      response = HTTParty.post("#{@base_url}#{path}", headers: auth_headers, body: body.to_json)
      parsed = JSON.parse(response.body)
      raise("Paddle API error: #{parsed['error']}") if parsed["error"]

      parsed
    end

    private

    def auth_headers
      {
        "Authorization" => "Bearer #{@api_key}",
        "Content-Type" => "application/json"
      }
    end
  end
end
