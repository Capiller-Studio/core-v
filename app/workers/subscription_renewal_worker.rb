# frozen_string_literal: true

class SubscriptionRenewalWorker < BaseMutexWorker
  def perform
    process_scheduled_cancellations
    renew_active_subscriptions
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
      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
        level: :error,
        account: subscription.account,
        message: "SubscriptionRenewalWorker failure on subscription##{subscription.id}: #{e.message}",
        payload: {
          worker: "SubscriptionRenewalWorker",
          subscription_id: subscription.id,
          error: e.message,
          backtrace: e.backtrace&.first(10)
        }
      )
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
      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
        level: :error,
        account: subscription.account,
        message: "Subscription cancellation failure on subscription##{subscription.id}: #{e.message}",
        payload: {
          worker: "SubscriptionRenewalWorker#process_scheduled_cancellations",
          subscription_id: subscription.id,
          error: e.message,
          backtrace: e.backtrace&.first(10)
        }
      )
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
        next_usage_reset_at: 1.month.from_now,
        status: :active,
        trial_end_at: nil,
        data: subscription.data.merge("max_agents_in_period" => 0)
      )

      account.reset_monthly_counters!
      grant_monthly_ai_credits(subscription)

      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::BILLING_SUBSCRIPTION_RENEWED,
        level: :info,
        account: account,
        message: "Subscription successfully renewed for #{account.name} (#{plan.name.capitalize}) until #{new_end.to_date}",
        payload: {
          subscription_id: subscription.id,
          plan: plan.name,
          amount: subscription.total_price.to_f,
          currency: account.currency,
          period_end: new_end
        }
      )
    else
      subscription.update!(status: :past_due)

      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::BILLING_PAYMENT_FAILED,
        level: :error,
        account: account,
        message: "Subscription renewal payment failed for #{account.name} (#{plan.name.capitalize}) - marked as past_due",
        payload: {
          subscription_id: subscription.id,
          plan: plan.name,
          amount: subscription.total_price.to_f,
          currency: account.currency,
          error: result[:error]
        }
      )

      owner = account.account_users.find_by(owner: true)&.user
      return unless owner

      account.with_shard do
        Notification.create!(
          account:,
          user: owner,
          resource: subscription,
          event: :payment_failed
        )
      end
    end
  end

  def grant_monthly_ai_credits(subscription)
    monthly_credits = subscription.plan.features.fetch("monthly_ai_credits", 0).to_i
    return if monthly_credits <= 0

    wallet = subscription.account.ai_wallet
    
    # 1. Expire any existing monthly free grants (non-rolling)
    wallet.credit_grants.monthly_free.active.update_all(balance: 0, expires_at: Time.current)

    # 2. Issue a new grant for the new billing cycle
    expires_at = 1.month.from_now
    
    wallet.grant_credits!(
      monthly_credits,
      grant_type: :monthly_free,
      expires_at: expires_at,
      description: "billing.events.monthly_ai_grant",
      data: { "plan" => subscription.plan.name }
    )
  end
end
