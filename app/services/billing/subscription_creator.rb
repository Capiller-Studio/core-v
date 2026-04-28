# frozen_string_literal: true

module Billing
  class SubscriptionCreator < ApplicationService
    attr_accessor :account, :plan, :billing_cycle

    def initialize(account:, plan:, billing_cycle: :monthly)
      self.account = account
      self.plan = plan
      self.billing_cycle = billing_cycle
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
      raise "Account already has an active subscription" if account.subscribed?
      raise "Plan is not available" unless plan.active?
      raise "Enterprise plan requires contacting sales" if plan.contact_us?
    end

    def create_subscription
      now = Time.current

      attrs = {
        account:,
        plan:,
        billing_cycle:,
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
        raise "Payment failed: #{result[:error]}" if result[:status] == :failed

        attrs.merge!(
          status: :active,
          current_period_start: now,
          current_period_end: period_end(now)
        )
      end

      subscription = Subscription.create!(attrs)
      sync_plan_limits
      subscription
    end

    def charge_for_subscription
      agent_count = [account.account_users.count, 1].max
      amount = plan.price_for(billing_cycle) * agent_count

      Billing::ChargeProcessor.call(
        account:,
        amount:,
        currency: account.currency,
        description: "#{plan.name.capitalize} plan subscription"
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
      account.update_column(:limits, new_limits)
    end
  end
end
