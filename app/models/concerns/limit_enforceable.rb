# frozen_string_literal: true

module LimitEnforceable
  extend ActiveSupport::Concern

  # Usage is tracked in Account.limits jsonb:
  # { "users": { "current": 1, "max": 2 },
  #   "channels": { "current": 1, "max": 1 },
  #   "customers": { "current": 45, "max": 500 },
  #   "conversations_monthly": { "current": 12, "max": 100 },
  #   "messages_monthly": { "current": 67, "max": 500 } }
  #
  # "max" comes from the plan, "current" is tracked here.
  # -1 means unlimited.

  RESOURCES = %w[users channels customers automations conversations_monthly messages_monthly custom_domains csat_surveys email_templates email_template_layouts].freeze

  def within_limit?(resource)
    plan = current_plan
    return true unless plan

    max = plan.limit_for(resource)
    return true if max == -1

    current_usage(resource) < max
  end

  def limit_reached?(resource, strict: true)
    return !within_limit?(resource) if strict

    # Soft block: Allow 10% buffer for monthly resources to improve UX
    is_monthly = resource.to_s.include?("monthly")
    buffer = is_monthly ? 1.1 : 1.0

    plan = current_plan
    return false unless plan

    max = plan.limit_for(resource)
    return false if max == -1

    current_usage(resource) >= (max * buffer)
  end

  def limit_approaching?(resource, threshold: 0.8)
    plan = current_plan
    return false unless plan

    max = plan.limit_for(resource)
    return false if max == -1

    current_usage(resource) >= (max * threshold)
  end

  def current_usage(resource)
    limits.dig(resource.to_s, "current") || 0
  end

  def usage_percentage(resource)
    plan = current_plan
    return 0 unless plan

    max = plan.limit_for(resource)
    return 0 if max == -1

    [ (current_usage(resource).to_f / max * 100).round(1), 100 ].min
  end

  def increment_usage!(resource)
    current = current_usage(resource)
    new_limits = limits.deep_dup
    new_limits[resource.to_s] ||= {}
    new_limits[resource.to_s]["current"] = current + 1
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations

    check_limit_notifications(resource)
  end

  def decrement_usage!(resource)
    current = current_usage(resource)
    new_limits = limits.deep_dup
    new_limits[resource.to_s] ||= {}
    new_limits[resource.to_s]["current"] = [ current - 1, 0 ].max
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def reset_monthly_counters!
    new_limits = limits.deep_dup
    %w[conversations_monthly messages_monthly].each do |resource|
      new_limits[resource] ||= {}
      new_limits[resource]["current"] = 0
    end
    new_limits["last_reset_at"] = Time.current.iso8601
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def check_limit_notifications(resource)
    return unless current_plan

    if limit_reached?(resource)
      create_limit_notification(:limit_reached, resource)
    elsif limit_approaching?(resource)
      create_limit_notification(:limit_approaching, resource)
    end
  end

  def create_limit_notification(event, resource)
    owner = account_users.find_by(owner: true)&.user
    return unless owner

    Notification.create(
      account: self,
      user: owner,
      resource: self,
      event:
    )
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
