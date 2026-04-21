# frozen_string_literal: true

class TrialExpirationWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  # TODO: Configure in scheduled.rb (daily)

  def perform
    # Notify accounts 3 days before trial expires
    Subscription.expiring_soon(3).find_each do |subscription|
      notify_trial_expiring(subscription)
    end

    # Expire trials that have ended
    Subscription.where(status: :trialing)
                .where("trial_end_at <= ?", Time.current)
                .find_each do |subscription|
      expire_trial(subscription)
    end
  end

  private

  def expire_trial(subscription)
    account = subscription.account
    payment_method = account.default_payment_method

    if payment_method
      # Has payment method — convert to active and charge
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
          subscription.update!(status: :active, current_period_start: now, current_period_end: new_end)
          return
        end
      rescue StandardError => e
        Rails.logger.error("Trial conversion charge failed: #{e.message}")
      end
    end

    # No payment method or charge failed — downgrade to free
    subscription.update!(status: :expired)
    Billing::SubscriptionCanceller.call(subscription:, immediate: true)
  end

  def notify_trial_expiring(subscription)
    owner = subscription.account.account_users.find_by(role: :owner)&.user
    return unless owner

    Notification.create!(
      account: subscription.account,
      user: owner,
      resource: subscription,
      event: :trial_expiring
    )
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
