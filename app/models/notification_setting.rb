# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id             :uuid             not null, primary key
#  configurations :jsonb            not null
#  email_flags    :integer          default(0), not null
#  push_flags     :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  index_notification_settings_on_account_id              (account_id)
#  index_notification_settings_on_account_id_and_user_id  (account_id,user_id) UNIQUE
#  index_notification_settings_on_user_id                 (user_id)
#  index_notification_settings_on_user_id_and_created_at  (user_id,created_at)
#
class NotificationSetting < ShardRecord
  include FlagShihTzu

  belongs_to :account
  belongs_to :user

  has_flags 1 => :email_conversation_created,
            2 => :email_conversation_assigned,
            3 => :email_conversation_resolved,
            4 => :email_sla_breached,
            5 => :email_message_created,
            6 => :email_conversation_mention,
            7 => :email_subscription_created,
            8 => :email_subscription_renewed,
            9 => :email_subscription_cancelled,
            10 => :email_trial_expiring,
            11 => :email_payment_failed,
            12 => :email_limit_approaching,
            13 => :email_limit_reached,
            column: "email_flags"

  has_flags 1 => :push_conversation_created,
            2 => :push_conversation_assigned,
            3 => :push_conversation_resolved,
            4 => :push_sla_breached,
            5 => :push_message_created,
            6 => :push_conversation_mention,
            7 => :push_subscription_created,
            8 => :push_subscription_renewed,
            9 => :push_subscription_cancelled,
            10 => :push_trial_expiring,
            11 => :push_payment_failed,
            12 => :push_limit_approaching,
            13 => :push_limit_reached,
            column: "push_flags",
            flag_query_mode: :bit_operator

  def email_enabled_for?(event)
    flag = :"email_#{event}"
    respond_to?(flag) ? send(flag) : false
  end

  def push_enabled_for?(event)
    flag = :"push_#{event}"
    respond_to?(flag) ? send(flag) : false
  end
end
