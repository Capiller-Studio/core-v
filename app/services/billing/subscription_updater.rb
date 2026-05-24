# frozen_string_literal: true

module Billing
  class SubscriptionUpdater < ApplicationService
    attr_accessor :subscription, :new_quantity, :new_plan

    def initialize(subscription:, new_quantity: nil, new_plan: nil)
      self.subscription = subscription
      self.new_quantity = new_quantity || subscription.quantity
      self.new_plan = new_plan || subscription.plan
    end

    def call
      lock_key = ::RedisUtilities::Keys::SUBSCRIPTION_LOCK % { account_id: subscription.account_id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          validate!
          update_subscription!
        end
      end
    end

    private

    def validate!
      raise("Subscription must be active to update") unless subscription.active?
      raise("New quantity must be at least #{new_plan.min_users}") if new_quantity < new_plan.min_users
      raise("New quantity cannot exceed #{new_plan.max_users}") if new_plan.max_users != -1 && new_quantity > new_plan.max_users
      raise("New quantity cannot be less than currently active users (#{subscription.account.users_count})") if new_quantity < subscription.account.users_count
      
      # Additional Guard: Prevent changing to a plan with max seats lower than current active seats
      if new_plan.max_users != -1 && subscription.account.users_count > new_plan.max_users
        raise("Cannot downgrade to #{new_plan.name} as it only allows #{new_plan.max_users} users, but you have #{subscription.account.users_count} active.")
      end

      # Cross currency migrations natively blocked
      raise("Plan currency mismatch") if new_plan.currency != subscription.plan.currency
    end

    def update_subscription!
      return if subscription.quantity == new_quantity && subscription.plan_id == new_plan.id

      seats_diff = new_quantity - subscription.quantity
      
      # Step 1: Calculate unused credit from the OLD plan
      old_daily_rate = subscription.total_price / subscription.total_days_in_cycle
      unused_credit = (old_daily_rate * subscription.remaining_days_in_cycle).round(2)
      
      # Step 2: Calculate remaining charge for the NEW plan
      new_total_price = (subscription.annual? ? new_plan.annual_price : new_plan.base_price) * new_quantity
      new_daily_rate = new_total_price / subscription.total_days_in_cycle
      remaining_charge = (new_daily_rate * subscription.remaining_days_in_cycle).round(2)
      
      # Step 3: Determine net difference
      net_diff = (remaining_charge - unused_credit).round(2)

      if net_diff.positive?
        charge_for_upgrade(net_diff, seats_diff)
      elsif net_diff.negative?
        credit_for_downgrade(net_diff.abs, seats_diff.abs)
      end

      subscription.update!(quantity: new_quantity, plan: new_plan)
      sync_plan_limits
    end

    def charge_for_upgrade(amount, seats_added)
      return if amount <= 0

      Billing::ChargeProcessor.call(
        account: subscription.account,
        amount: amount,
        currency: subscription.currency,
        description: "Upgraded subscription by #{seats_added} seats (prorated)",
        subscription: subscription
      )
    end

    def credit_for_downgrade(amount, seats_removed)
      return if amount <= 0

      # Credit the wallet
      wallet = subscription.account.wallet
      wallet.add!(amount, description: "Prorated credit for removing #{seats_removed} seats")

      # Create a refund transaction for the original charge so affiliates can clawback
      transaction = Transaction.create!(
        account: subscription.account,
        subscription: subscription,
        transaction_type: :refund,
        status: :completed,
        amount: amount,
        currency: subscription.currency,
        provider: :wallet,
        description: "Prorated refund for #{seats_removed} seats",
        data: { "refunded_seats" => seats_removed }
      )

      # Clawback the affiliate commission natively against the most recent charge
      original_charge = subscription.transactions.where(transaction_type: :charge, status: :completed).order(created_at: :desc).first
      if original_charge
        Affiliates::Commissions::Refunder.call(transaction: original_charge, refund_amount: amount)
      end
    end

    def sync_plan_limits
      new_limits = subscription.account.limits.deep_dup
      subscription.plan.limits.each do |resource, max|
        new_limits[resource] ||= {}
        new_limits[resource]["max"] = max
      end
      # rubocop:disable Rails/SkipsModelValidations
      subscription.account.update_column(:limits, new_limits)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
