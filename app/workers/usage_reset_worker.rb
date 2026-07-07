# frozen_string_literal: true

class UsageResetWorker
  include Sidekiq::Worker
  sidekiq_options retry: 1, queue: "default"

  # Resets monthly usage counters for accounts whose billing period just started

  def perform
    Subscription.where(status: :active)
                .where("current_period_start::date = ?", Date.current)
                .find_each do |subscription|
      subscription.account.reset_monthly_counters!
    end
  end
end
