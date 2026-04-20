# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id            :uuid             not null, primary key
#  event         :integer          default("conversation_created"), not null
#  read_at       :datetime
#  resource_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null
#  resource_id   :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_notifications_on_account_id              (account_id)
#  index_notifications_on_resource                (resource_type,resource_id)
#  index_notifications_on_user_id                 (user_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at)
#  index_notifications_on_user_id_and_event       (user_id,event)
#
class Notification < ShardRecord
  include Notifiable

  belongs_to :account
  belongs_to :user
  belongs_to :resource, polymorphic: true

  enum :event, {
    conversation_created: 0,
    conversation_assigned: 1,
    conversation_resolved: 2,
    sla_breached: 3,
    message_created: 4,
    conversation_mention: 5
  }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def event_payload
    {
      id:,
      event:,
      read_at:,
      resource_type:,
      resource_id:,
      created_at:
    }
  end
end
