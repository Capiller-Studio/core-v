# frozen_string_literal: true

class TrialExpirationWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  def perform
    # Notify accounts 3 days before trial expires
    Subscription.expiring_soon(3).find_each do |subscription|
      notify_trial_expiring(subscription)
    rescue StandardError => e
      Rails.logger.warn("[TrialExpirationWorker] Failed to notify trial expiring for sub##{subscription.id}: #{e.message}")
    end

    # Expire trials that have ended
    Subscription.where(status: :trialing)
                .where(trial_end_at: ..Time.current)
                .find_each do |subscription|
      begin
        expire_trial(subscription)
      rescue StandardError => e
        Rails.logger.error("Failed to expire trial for subscription##{subscription.id}: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error,
          account: subscription.account,
          message: "TrialExpirationWorker failure on subscription##{subscription.id}: #{e.message}",
          payload: {
            worker: "TrialExpirationWorker",
            subscription_id: subscription.id,
            error: e.message,
            backtrace: e.backtrace&.first(10)
          }
        )
      end
    end
  end

  private

  def expire_trial(subscription)
    account = subscription.account
    payment_method = account.default_payment_method
    wallet = account.wallet
    has_sufficient_wallet = wallet.present? && wallet.balance.to_d >= subscription.total_price.to_d

    if payment_method.present? || has_sufficient_wallet
      # Has payment method or sufficient wallet balance — convert to active and charge
      begin
        result = Billing::ChargeProcessor.call(
          account:,
          amount: subscription.total_price,
          currency: account.currency,
          description: "#{subscription.plan.name.capitalize} plan — trial conversion",
          subscription:
        )

        if result[:status] == :completed
          now = Time.current
          new_end = subscription.annual? ? now + 1.year : now + 1.month
          subscription.update!(
            status: :active,
            current_period_start: now,
            current_period_end: new_end,
            next_usage_reset_at: 1.month.from_now
          )

          account.reset_monthly_counters!
          grant_monthly_ai_credits(subscription)

          SystemLogs::Logger.call(
            event_key: SystemLogs::EventKeys::BILLING_TRIAL_CONVERTED,
            level: :info,
            account: account,
            message: "Trial successfully converted to active #{subscription.plan.name.capitalize} plan for #{account.name}",
            payload: {
              subscription_id: subscription.id,
              plan: subscription.plan.name,
              amount: subscription.total_price.to_f,
              currency: account.currency,
              wallet_balance: wallet&.balance.to_f
            }
          )
          return
        else
          SystemLogs::Logger.call(
            event_key: SystemLogs::EventKeys::BILLING_PAYMENT_FAILED,
            level: :error,
            account: account,
            message: "Trial conversion charge failed for #{account.name} (#{subscription.plan.name.capitalize}): #{result[:error]}",
            payload: {
              subscription_id: subscription.id,
              plan: subscription.plan.name,
              amount: subscription.total_price.to_f,
              currency: account.currency,
              error: result[:error]
            }
          )
        end
      rescue StandardError => e
        Rails.logger.error("Trial conversion charge failed: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::BILLING_PAYMENT_FAILED,
          level: :error,
          account: account,
          message: "Trial conversion charge exception for #{account.name}: #{e.message}",
          payload: { subscription_id: subscription.id, error: e.message }
        )
      end
    end

    # No payment method, insufficient wallet balance, or charge failed — downgrade to free
    subscription.update!(status: :expired)
    Billing::SubscriptionCanceller.call(subscription:, immediate: true)

    SystemLogs::Logger.call(
      event_key: SystemLogs::EventKeys::BILLING_TRIAL_EXPIRED,
      level: :warn,
      account: account,
      message: "Trial expired for #{account.name} (#{subscription.plan.name.capitalize}) - downgraded to free plan",
      payload: {
        subscription_id: subscription.id,
        plan: subscription.plan.name,
        total_price: subscription.total_price.to_f,
        wallet_balance: wallet&.balance.to_f,
        has_payment_method: payment_method.present?
      }
    )
  end

  def notify_trial_expiring(subscription)
    account = subscription.account
    owner = account.account_users.find_by(owner: true)&.user
    return unless owner

    already_notified = account.with_shard do
      Notification.exists?(
        account: account,
        user: owner,
        resource: subscription,
        event: :trial_expiring,
        created_at: 3.days.ago..
      )
    end
    return if already_notified

    account.with_shard do
      Notification.create!(
        account: account,
        user: owner,
        resource: subscription,
        event: :trial_expiring
      )
    end
  rescue StandardError => e
    Rails.logger.warn("[TrialExpirationWorker] Failed to notify trial expiring: #{e.message}")
  end

  def grant_monthly_ai_credits(subscription)
    monthly_credits = subscription.plan.features.fetch("monthly_ai_credits", 0).to_i
    return if monthly_credits <= 0

    wallet = subscription.account.ai_wallet
    
    # 1. Expire any existing monthly free grants (non-rolling)
    wallet.credit_grants.monthly_free.active.update_all(balance: 0, expires_at: Time.current)

    # 2. Issue a new grant for the new billing cycle
    wallet.grant_credits!(
      monthly_credits,
      grant_type: :monthly_free,
      expires_at: 1.month.from_now,
      description: "billing.events.monthly_ai_grant",
      data: { "plan" => subscription.plan.name }
    )
  end
end
