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

  RESOURCES = %w[
    users
    channels
    ai_agents
    automations
    macros
    sla_policies
    csat_surveys
    email_templates
    email_template_layouts
    help_center_portals
    custom_domains
    business_hour_groups
    teams
    custom_roles
    assignment_policies
    identity_sources
    custom_fields
    customers
    conversations_monthly
    messages_monthly
  ].freeze

  def within_limit?(resource)
    plan = current_plan
    return true unless plan

    max = plan.limit_for(resource)
    return true if max == -1

    current_usage(resource) < max
  end

  def limit_reached?(resource, strict: true)
    return !within_limit?(resource) if strict

    # Soft block: Allow 10% buffer for monthly resources and customers to improve UX
    is_soft = resource.to_s.include?("monthly") || resource.to_s == "customers"
    buffer = is_soft ? 1.1 : 1.0

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
    (limits || {}).dig(resource.to_s, "current") || 0
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
    new_usage = current + 1
    new_limits = (limits || {}).deep_dup
    new_limits[resource.to_s] ||= {}
    new_limits[resource.to_s]["current"] = new_usage
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations

    check_limit_notifications(resource, previous_usage: current, new_usage: new_usage)
  end

  def decrement_usage!(resource)
    current = current_usage(resource)
    new_limits = (limits || {}).deep_dup
    new_limits[resource.to_s] ||= {}
    new_limits[resource.to_s]["current"] = [ current - 1, 0 ].max
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def reset_monthly_counters!
    new_limits = (limits || {}).deep_dup
    %w[conversations_monthly messages_monthly].each do |resource|
      new_limits[resource] ||= {}
      new_limits[resource]["current"] = 0
      new_limits[resource].delete("notified_80_at")
      new_limits[resource].delete("notified_100_at")
    end
    new_limits["last_reset_at"] = Time.current.iso8601
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def check_limit_notifications(resource, previous_usage: nil, new_usage: nil)
    return unless current_plan

    max = current_plan.limit_for(resource)
    return if max == -1 || max.zero?

    curr_usage = new_usage || current_usage(resource)
    prev_usage = previous_usage || (curr_usage - 1)

    threshold_80 = (max * 0.8).ceil
    threshold_100 = max

    # 1. 100% Boundary Crossing: previous < 100% and current >= 100%
    if prev_usage < threshold_100 && curr_usage >= threshold_100
      dispatch_idempotent_limit_notification(:limit_reached, resource, threshold: "100")
    # 2. 80% Boundary Crossing: previous < 80% and current >= 80%
    elsif prev_usage < threshold_80 && curr_usage >= threshold_80
      dispatch_idempotent_limit_notification(:limit_approaching, resource, threshold: "80")
    end
  end

  private

  def dispatch_idempotent_limit_notification(event, resource, threshold:)
    is_monthly = resource.to_s.include?("monthly")
    window = if is_monthly
               limits&.dig("last_reset_at") ? Time.zone.parse(limits["last_reset_at"]).strftime("%Y%m%d") : Time.current.strftime("%Y%m")
    else
               Time.current.strftime("%G-W%V")
    end

    lock_key = ::RedisUtilities::Keys::LIMIT_NOTIFICATION_LOCK % {
      account_id: id,
      resource: resource,
      threshold: threshold,
      window: window
    }

    # 1. Redis atomic lock check (TTL: 35 days for monthly, 8 days for weekly)
    ttl = is_monthly ? 35.days.to_i : 8.days.to_i
    acquired = ::RedisUtilities::Helpers.set(lock_key, "1", overwrite: false, expiry: ttl)
    return unless acquired

    # 2. Persist notification state to DB limits jsonb
    new_limits = (limits || {}).deep_dup
    new_limits[resource.to_s] ||= {}
    new_limits[resource.to_s]["notified_#{threshold}_at"] = Time.current.iso8601
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:limits, new_limits)
    # rubocop:enable Rails/SkipsModelValidations

    create_limit_notification(event, resource)
  rescue StandardError => e
    Rails.logger.error("Failed to dispatch limit notification: #{e.message}")
  end

  def create_limit_notification(event, resource)
    owner = account_users.find_by(owner: true)&.user
    return unless owner

    Notification.create(
      account: self,
      user: owner,
      resource: self,
      event: event
    )
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
