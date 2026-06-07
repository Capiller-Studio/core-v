# frozen_string_literal: true

module Billing
  class SubscriptionCreator < ApplicationService
    attr_accessor :account, :plan, :billing_cycle, :quantity

    def initialize(account:, plan:, billing_cycle: :monthly, quantity: 1)
      self.account = account
      self.plan = plan
      self.billing_cycle = billing_cycle
      self.quantity = quantity
    end

    def call
      lock_key = ::RedisUtilities::Keys::SUBSCRIPTION_LOCK % { account_id: account.id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          validate!
          create_subscription
        end
      end
    end

    private

    def validate!
      raise("Account already has an active subscription") if account.subscribed?
      raise("Plan is not available") unless plan.active?
      raise("Plan currency mismatch") if plan.currency != account.currency
    end

    def create_subscription
      now = Time.current

      attrs = {
        account:,
        plan:,
        billing_cycle:,
        quantity:,
        currency: plan.currency,
        provider: PaymentGateway::Resolver.default_provider
      }

      if plan.free?
        attrs.merge!(
          status: :active,
          current_period_start: now,
          current_period_end: nil
        )
      elsif plan.trial_days.positive?
        attrs.merge!(
          status: :trialing,
          trial_end_at: now + plan.trial_days.days,
          current_period_start: now,
          current_period_end: now + plan.trial_days.days
        )
      else
        result = charge_for_subscription
        raise("Payment failed: #{result[:error]}") if result[:status] == :failed

        attrs.merge!(
          status: :active,
          current_period_start: now,
          current_period_end: period_end(now)
        )
      end

      subscription = Subscription.create!(attrs)

      if defined?(result) && result && result[:transactions].present?
        Transaction.where(id: result[:transactions].map(&:id)).update_all(subscription_id: subscription.id)
      end

      sync_plan_limits
      subscription
    end

    def charge_for_subscription
      amount = plan.price_for(billing_cycle) * quantity

      Billing::ChargeProcessor.call(
        account:,
        amount:,
        currency: plan.currency,
        description: "#{plan.name.capitalize} plan subscription (#{quantity} seats)"
      )
    end

    def period_end(from)
      case billing_cycle.to_s
      when "annual" then from + 1.year
      else from + 1.month
      end
    end

    def sync_plan_limits
      new_limits = account.limits.deep_dup
      plan.limits.each do |resource, max|
        new_limits[resource] ||= {}
        new_limits[resource]["max"] = max
        new_limits[resource]["current"] ||= 0
      end
      # rubocop:disable Rails/SkipsModelValidations
      account.update_column(:limits, new_limits)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
