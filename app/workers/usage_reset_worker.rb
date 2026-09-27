# frozen_string_literal: true

class UsageResetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  # Resets monthly usage counters for accounts whose billing period just started

  def perform
    today = Date.current

    # We now filter directly in SQL for any active subscription due for a usage reset!
    Subscription.where(status: :active)
                .where(next_usage_reset_at: ..Time.current)
                .find_each do |subscription|
      
      begin
        # 1. Reset standard usage limits
        subscription.account.reset_monthly_counters!

        # 2. Grant fresh AI credits
        grant_monthly_ai_credits(subscription)

        # 3. Calculate exactly when the NEXT reset should happen
        # Using advance(months: 1) keeps it anchored closely to the start_date's day-of-month,
        # but if they were overdue by several months, we must skip forward to the correct future date.
        next_reset = calculate_next_reset(subscription.next_usage_reset_at, today)
        subscription.update!(next_usage_reset_at: next_reset)
      rescue StandardError => e
        Rails.logger.error("Usage reset failed for subscription##{subscription.id}: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error,
          account: subscription.account,
          message: "UsageResetWorker failure on subscription##{subscription.id}: #{e.message}",
          payload: {
            worker: "UsageResetWorker",
            subscription_id: subscription.id,
            error: e.message,
            backtrace: e.backtrace&.first(10)
          }
        )
      end
    end
  end

  private

  def calculate_next_reset(current_reset_date, today)
    # E.g. current_reset_date was Jan 15th. Today is Mar 16th.
    # We must advance months until it's in the future.
    next_date = current_reset_date.to_date
    while next_date <= today
      next_date = next_date.next_month
    end
    
    # Preserve the time from current_reset_date if possible (though we mainly care about the day)
    current_reset_date.change(year: next_date.year, month: next_date.month, day: next_date.day)
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
