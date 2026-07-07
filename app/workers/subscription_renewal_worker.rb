# frozen_string_literal: true

class SubscriptionRenewalWorker < BaseMutexWorker
  def perform
    renew_active_subscriptions
    process_scheduled_cancellations
  end

  private

  def renew_active_subscriptions
    Subscription.due_for_renewal.find_each do |subscription|
      lock_key = RedisUtilities::Keys::RENEWAL_LOCK % { account_id: subscription.account_id }

      RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          renew_subscription(subscription)
        end
      end
    rescue MutexLockError
      # Another process is handling this — skip
    rescue StandardError => e
      Rails.logger.error("Renewal failed for subscription##{subscription.id}: #{e.message}")
    end
  end

  def process_scheduled_cancellations
    Subscription.where(status: :active)
                .where.not(cancelled_at: nil)
                .where(current_period_end: ..Time.current)
                .find_each do |subscription|
      Billing::SubscriptionCanceller.call(subscription:, immediate: true)
    rescue StandardError => e
      Rails.logger.error("Cancellation failed for subscription##{subscription.id}: #{e.message}")
    end
  end

  def renew_subscription(subscription)
    account = subscription.account
    plan = subscription.plan

    return if plan.free?

    # Track max agents for anti-gaming billing
    subscription.record_agent_count(account.account_users.count)

    result = Billing::ChargeProcessor.call(
      account:,
      amount: subscription.total_price,
      currency: account.currency,
      description: "#{plan.name.capitalize} plan renewal",
      subscription:
    )

    if result[:status] == :completed
      now = Time.current
      new_end = subscription.annual? ? now + 1.year : now + 1.month

      subscription.update!(
        current_period_start: now,
        current_period_end: new_end,
        data: subscription.data.merge("max_agents_in_period" => 0)
      )

      account.reset_monthly_counters!
    else
      subscription.update!(status: :past_due)

      owner = account.account_users.find_by(owner: true)&.user
      return unless owner

      Notification.create!(
        account:,
        user: owner,
        resource: subscription,
        event: :payment_failed
      )
    end
  end
end
