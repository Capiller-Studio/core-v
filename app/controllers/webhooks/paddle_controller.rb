# frozen_string_literal: true

module Webhooks
  class PaddleController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_paddle_signature

    def create
      event_type = params["event_type"]
      data = params["data"]

      ActiveRecord::Base.transaction do
        case event_type
        when "transaction.completed"
          handle_transaction_completed(data)
        when "subscription.created"
          handle_subscription_created(data)
        when "subscription.updated"
          handle_subscription_updated(data)
        when "subscription.canceled"
          handle_subscription_canceled(data)
        when "subscription.past_due"
          handle_subscription_past_due(data)
        end
      end

      head(:ok)
    rescue StandardError => e
      Rails.logger.error("Paddle webhook error: #{e.message}")
      head(:bad_request)
    end

    private

    def verify_paddle_signature
      # Paddle signs webhooks with a shared secret
      webhook_secret = Rails.application.credentials.dig(:paddle, :webhook_secret)
      return head(:unauthorized) unless webhook_secret

      signature = request.headers["Paddle-Signature"]
      return head(:unauthorized) unless signature

      # Parse ts and h1 from "ts=...;h1=..."
      parts = signature.split(";").to_h { |p| p.split("=", 2) }
      ts = parts["ts"]
      h1 = parts["h1"]

      payload = "#{ts}:#{request.raw_post}"
      computed = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, payload)

      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(computed, h1)
    end

    def handle_transaction_completed(data)
      custom_data = data.dig("custom_data") || {}
      account_id = custom_data["account_id"]
      return unless account_id

      account = Account.find(account_id)

      # Record the transaction
      Transaction.create!(
        account:,
        transaction_type: :charge,
        status: :completed,
        amount: data.dig("details", "totals", "total").to_d / 100,
        currency: data.dig("currency_code") || "USD",
        provider: :paddle,
        external_id: data["id"],
        description: "Paddle checkout payment"
      )

      # Save payment method from checkout
      if data.dig("payment", "method_details").present?
        Billing::PaymentMethodManager
          .new(account:)
          .handle_paddle_payment_method({ "data" => data })
      end
    end

    def handle_subscription_created(data)
      custom_data = data.dig("custom_data") || {}
      account_id = custom_data["account_id"]
      plan_id = custom_data["plan_id"]
      billing_cycle = custom_data["billing_cycle"] || "monthly"

      return unless account_id && plan_id

      account = Account.find(account_id)
      plan = Plan.find(plan_id)

      # Don't double-create if we already have one
      return if account.subscribed?

      now = Time.current
      period_end = data["current_billing_period"] ? Time.zone.parse(data["current_billing_period"]["ends_at"]) : now + 1.month

      Subscription.create!(
        account:,
        plan:,
        status: :active,
        billing_cycle: billing_cycle.to_sym,
        provider: :paddle,
        external_id: data["id"],
        current_period_start: now,
        current_period_end: period_end
      )

      # Sync limits
      new_limits = account.limits.deep_dup
      plan.limits.each { |r, m| new_limits[r] = { "max" => m, "current" => new_limits.dig(r, "current") || 0 } }
      # rubocop:disable Rails/SkipsModelValidations
      account.update_column(:limits, new_limits)
      # rubocop:enable Rails/SkipsModelValidations
    end

    def handle_subscription_updated(data)
      subscription = Subscription.find_by(external_id: data["id"])
      return unless subscription

      if data["current_billing_period"]
        subscription.update!(
          current_period_start: Time.zone.parse(data["current_billing_period"]["starts_at"]),
          current_period_end: Time.zone.parse(data["current_billing_period"]["ends_at"])
        )
      end
    end

    def handle_subscription_canceled(data)
      subscription = Subscription.find_by(external_id: data["id"])
      return unless subscription

      Billing::SubscriptionCanceller.call(subscription:, immediate: true)
    end

    def handle_subscription_past_due(data)
      subscription = Subscription.find_by(external_id: data["id"])
      return unless subscription

      subscription.update!(status: :past_due)

      owner = subscription.account.account_users.find_by(owner: true)&.user
      return unless owner

      Notification.create!(
        account: subscription.account,
        user: owner,
        resource: subscription,
        event: :payment_failed
      )
    end
  end
end
