# frozen_string_literal: true

module Webhooks
  class PaddleEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        event_type = webhook.payload["event_type"]
        data = webhook.payload["data"]

        alert_id = webhook.payload["alert_id"] || data["id"]
        lock_key = format(::RedisUtilities::Keys::WEBHOOK_EVENT_LOCK, provider: "paddle", event_id: alert_id)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
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
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise(e)
      end
    end

    private

    def handle_transaction_completed(data)
      custom_data = data.dig("custom_data") || {}
      account_id = custom_data["account_id"]
      return unless account_id

      account = Account.find(account_id)

      Transaction.create!(
        account: account,
        transaction_type: :charge,
        status: :completed,
        amount: data.dig("details", "totals", "total").to_d / 100,
        currency: data.dig("currency_code") || "USD",
        provider: :paddle,
        external_id: data["id"],
        description: "Paddle checkout payment"
      )

      if data.dig("payment", "method_details").present?
        Billing::PaymentMethodManager
          .new(account: account)
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

      return if account.subscribed?

      now = Time.current
      period_end = data["current_billing_period"] ? Time.zone.parse(data["current_billing_period"]["ends_at"]) : now + 1.month

      Subscription.create!(
        account: account,
        plan: plan,
        quantity: [account.users_count, 1].max,
        currency: plan.currency,
        status: :active,
        billing_cycle: billing_cycle.to_sym,
        provider: :paddle,
        external_id: data["id"],
        current_period_start: now,
        current_period_end: period_end
      )

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

      Billing::SubscriptionCanceller.call(subscription: subscription, immediate: true)
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
