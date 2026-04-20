# frozen_string_literal: true

class NotificationDeliveryWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3, queue: "default"

  def perform(notification_id, account_id)
    notification = Notification.find_by(id: notification_id, account_id:)
    return unless notification

    user = notification.user
    setting = NotificationSetting.find_by(account_id:, user_id: user.id)

    deliver_realtime(notification, user)
    deliver_email(notification, setting)
    deliver_push(notification, user, setting)
  end

  private

  # Always deliver via ActionCable for realtime UI updates
  def deliver_realtime(notification, user)
    ActionCable.server.broadcast(
      user.connection_token,
      { event: "notification.created", object: notification.event_payload }
    )
  end

  # Send email if user's notification settings allow it
  def deliver_email(notification, setting)
    return if setting && !setting.email_enabled_for?(notification.event)

    AgentNotificationMailer.notify(notification).deliver_later
  rescue StandardError => e
    Rails.logger.error("Email notification delivery failed: #{e.message}")
  end

  # Send push notification if user's settings allow it
  def deliver_push(notification, user, setting)
    return if setting && !setting.push_enabled_for?(notification.event)

    subscriptions = NotificationSubscription.where(user_id: user.id)
    subscriptions.find_each do |subscription|
      subscription.deliver_push!(notification)
    end
  end
end
