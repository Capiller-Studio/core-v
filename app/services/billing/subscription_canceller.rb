# frozen_string_literal: true

module Billing
  class SubscriptionCanceller < ApplicationService
    attr_accessor :subscription, :immediate

    def initialize(subscription:, immediate: false)
      self.subscription = subscription
      self.immediate = immediate
    end

    def call
      lock_key = ::RedisUtilities::Keys::SUBSCRIPTION_LOCK % { account_id: subscription.account_id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          if immediate
            cancel_immediately
          else
            schedule_cancellation
          end
        end
      end
    end

    private

    def cancel_immediately
      cancel_at_gateway if subscription.external_id.present?

      subscription.cancel!(immediate: true)
      downgrade_to_free_plan
    end

    def schedule_cancellation
      subscription.update!(cancelled_at: Time.current)
    end

    def cancel_at_gateway
      gateway = PaymentGateway::Resolver.for(subscription.account)
      gateway.cancel_subscription(subscription.external_id)
    rescue StandardError => e
      Rails.logger.error("Gateway cancellation failed: #{e.message}")
      # Don't block local cancellation — gateway can be synced later
    end

    def downgrade_to_free_plan
      free_plan = Plan.find_by(name: Plan::STARTER)
      return unless free_plan

      account = subscription.account
      Subscription.create!(
        account:,
        plan: free_plan,
        status: :active,
        billing_cycle: :monthly,
        current_period_start: Time.current,
        provider: subscription.provider
      )

      new_limits = account.limits.deep_dup
      free_plan.limits.each do |resource, max|
        new_limits[resource] ||= {}
        new_limits[resource]["max"] = max
      end
      account.update_column(:limits, new_limits)
    end
  end
end
