# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :plan

  has_many :transactions, dependent: :nullify

  enum :status, { active: 0, trialing: 1, past_due: 2, cancelled: 3, expired: 4 }
  enum :billing_cycle, { monthly: 0, annual: 1 }
  enum :provider, { stripe: 0, paddle: 1 }

  scope :current, -> { where(status: [ :active, :trialing ]) }
  scope :expiring_soon, ->(days = 3) { where(trial_end_at: ..days.days.from_now).where(status: :trialing) }
  scope :due_for_renewal, -> { where(current_period_end: ..Time.current).where(status: :active) }

  validates :account_id, uniqueness: { conditions: -> { where(status: [ :active, :trialing ]) },
                                       message: :active_subscription_exists }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :currency, presence: true, inclusion: { in: Core::SUPPORTED_CURRENCIES }
  validate :quantity_within_plan_limits

  def trialing?
    status == "trialing" && trial_end_at.present? && trial_end_at > Time.current
  end

  def trial_expired?
    status == "trialing" && trial_end_at.present? && trial_end_at <= Time.current
  end

  def active_or_trialing?
    active? || trialing?
  end

  def due_for_renewal?
    active? && current_period_end.present? && current_period_end <= Time.current
  end

  def days_until_trial_end
    return 0 unless trial_end_at

    [ (trial_end_at.to_date - Date.current).to_i, 0 ].max
  end

  def cancel!(immediate: false)
    if immediate
      update!(status: :cancelled, cancelled_at: Time.current)
    else
      update!(cancelled_at: Time.current)
      # Will be cancelled at period end by SubscriptionRenewalWorker
    end
  end

  # Anti-gaming: track max agents during billing period
  def record_agent_count(count)
    max = data["max_agents_in_period"] || 0
    if count > max
      update!(data: data.merge("max_agents_in_period" => count))
    end
  end

  def billable_agents
    quantity
  end

  def total_price
    case billing_cycle.to_s
    when "annual" then plan.annual_price * quantity
    else plan.base_price * quantity
    end
  end

  def remaining_days_in_cycle
    return 0 unless current_period_end && current_period_start
    return 0 if current_period_end <= Time.current

    (current_period_end.to_date - Date.current).to_i
  end

  def total_days_in_cycle
    return 30 unless current_period_end && current_period_start

    (current_period_end.to_date - current_period_start.to_date).to_i
  end

  private

  def quantity_within_plan_limits
    return unless plan && quantity

    if quantity < plan.min_users
      errors.add(:quantity, "must be at least #{plan.min_users} for this plan")
    end

    if plan.max_users != -1 && quantity > plan.max_users
      errors.add(:quantity, "cannot exceed #{plan.max_users} for this plan")
    end
  end
end
