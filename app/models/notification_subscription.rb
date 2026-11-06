# frozen_string_literal: true

require 'deskbolic_web_push'

# == Schema Information
#
# Table name: notification_subscriptions
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  name              :string
#  subscription_type :integer          default("push"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_user_id_subscription_type_c17965cf4e                 (user_id,subscription_type)
#  index_notification_subscriptions_on_user_id                 (user_id)
#  index_notification_subscriptions_on_user_id_and_created_at  (user_id,created_at)
#
class NotificationSubscription < ShardRecord
  belongs_to :user

  enum :subscription_type, { push: 0, fcm: 1 }

  # Web Push: data stores { endpoint:, p256dh:, auth: }
  # FCM:      data stores { device_token: }

  def push_token
    data["device_token"] || data["endpoint"]
  end

  def web_push_keys
    {
      p256dh: data["p256dh"],
      auth: data["auth"]
    }
  end

  def deliver_push!(notification)
    case subscription_type
    when "push"
      deliver_web_push(notification)
    when "fcm"
      deliver_fcm(notification)
    end
  rescue StandardError => e
    Rails.logger.error("Push delivery failed for subscription##{id}: #{e.message}")
  end

  private

  # Use user's configured locale for push notification text
  def user_locale
    user.locale || I18n.default_locale
  end

  def deliver_web_push(notification)
    return if data["endpoint"].blank?

    payload = push_payload(notification)

    DeskbolicWebPush.payload_send(
      message: payload.to_json,
      endpoint: data["endpoint"],
      p256dh: data["p256dh"],
      auth: data["auth"],
      vapid: {
        subject: ENV['VAPID_SUBJECT'] || (Rails.application.credentials.dig(:vapid, :subject) ? "mailto:#{Rails.application.credentials.dig(:vapid, :subject)}" : "mailto:support@capiller.com"),
        public_key: ENV['VAPID_PUBLIC_KEY'] || Rails.application.credentials.dig(:vapid, :public_key),
        private_key: ENV['VAPID_PRIVATE_KEY'] || Rails.application.credentials.dig(:vapid, :private_key)
      }
    )
  end

  def deliver_fcm(notification)
    return if data["device_token"].blank?

    # TODO: Configure FCM credentials and implement
    Rails.logger.info("FCM push queued for device: #{data['device_token']}")
  end

  def push_payload(notification)
    locale = user_locale
    identifier = notification.resource.try(:identifier) || notification.resource.try(:conversation).try(:identifier) || ""
    inbox_name = notification.resource.try(:inbox).try(:name) || notification.resource.try(:conversation).try(:inbox).try(:name) || ""

    {
      title: I18n.t("notifications.push.#{notification.event}.title", locale:),
      body: I18n.t("notifications.push.#{notification.event}.body", locale:, identifier:, inbox_name:),
      data: {
        notification_id: notification.id,
        event: notification.event,
        resource_type: notification.resource_type,
        resource_id: notification.resource_id,
        conversation_id: notification.resource.try(:conversation_id)
      }
    }
  end
end
