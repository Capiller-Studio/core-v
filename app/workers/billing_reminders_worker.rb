# frozen_string_literal: true

class BillingRemindersWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform
    send_trial_reminders
    send_past_due_reminders
  end

  private

  def send_trial_reminders
    # Find active trialing subscriptions that end in exactly 3 days or 1 day
    Subscription.where(status: :trialing).find_each do |subscription|
      begin
        days_left = subscription.days_until_trial_end

        # We send a reminder when there are exactly 3 days left and 1 day left.
        if days_left == 3 || days_left == 1
          account = subscription.account

          # Don't send reminder if they already have a payment method
          next if account.payment_methods.active_methods.any?

          SystemMailer.subscription_reminder(account).deliver_later
        end
      rescue StandardError => e
        Rails.logger.error("Trial reminder failed for subscription##{subscription.id}: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error,
          account: subscription.account,
          message: "BillingRemindersWorker failure on subscription##{subscription.id}: #{e.message}",
          payload: {
            worker: "BillingRemindersWorker#send_trial_reminders",
            subscription_id: subscription.id,
            error: e.message,
            backtrace: e.backtrace&.first(10)
          }
        )
      end
    end
  end

  def send_past_due_reminders
    # Find subscriptions that are past due
    Subscription.where(status: :past_due).find_each do |subscription|
      begin
        account = subscription.account

        # Send a reminder if the subscription became past due in the last 24 hours,
        # or if we want to send periodic reminders we could check `updated_at`.
        # For now, we'll send a reminder if it's been exactly 1, 3, or 7 days since the period ended.
        days_past = (Time.current.to_date - subscription.current_period_end.to_date).to_i

        if [ 1, 3, 7 ].include?(days_past)
          SystemMailer.subscription_past_due(account).deliver_later
        end
      rescue StandardError => e
        Rails.logger.error("Past due reminder failed for subscription##{subscription.id}: #{e.message}")
        SystemLogs::Logger.call(
          event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
          level: :error,
          account: subscription.account,
          message: "BillingRemindersWorker past due failure on subscription##{subscription.id}: #{e.message}",
          payload: {
            worker: "BillingRemindersWorker#send_past_due_reminders",
            subscription_id: subscription.id,
            error: e.message,
            backtrace: e.backtrace&.first(10)
          }
        )
      end
    end
  end
end
