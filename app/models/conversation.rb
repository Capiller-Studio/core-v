# frozen_string_literal: true

# == Schema Information
#
# Table name: conversations
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  first_respond_at  :datetime
#  identifier        :string           not null
#  last_activity_at  :datetime
#  locale            :string
#  priority          :integer          default("low"), not null
#  source            :integer
#  status            :integer          default("active"), not null
#  status_changed_at :datetime
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  campaign_id       :uuid
#  external_id       :string
#  inbox_id          :uuid             not null
#
# Indexes
#
#  index_conversations_on_account_id                       (account_id)
#  index_conversations_on_account_id_and_created_at        (account_id,created_at)
#  index_conversations_on_account_id_and_external_id       (account_id,external_id)
#  index_conversations_on_account_id_and_identifier        (account_id,identifier) UNIQUE
#  index_conversations_on_account_id_and_last_activity_at  (account_id,last_activity_at)
#  index_conversations_on_account_id_and_priority          (account_id,priority)
#  index_conversations_on_account_id_and_status            (account_id,status)
#  index_conversations_on_account_id_and_title             (account_id,title)
#  index_conversations_on_campaign_id                      (campaign_id)
#  index_conversations_on_inbox_id                         (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id) ON DELETE => nullify
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
class Conversation < ShardRecord
  include Assignable
  include SlaTrackable

  belongs_to :account
  belongs_to :inbox
  belongs_to :campaign, optional: true

  enum :status, { active: 0, closed: 1, snoozed: 2, resolved: 3 }
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }
  enum :source, {
    email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3,
    api: 4, web_widget: 5, sms: 6, telegram: 7,
    help_center: 8  # Submitted via a Channel::ContactForm on a Help Center portal
  }, suffix: true

  has_many :conversation_members, dependent: :destroy
  has_many :members, through: :conversation_members, source: :member, source_type: [ "Customer", "User" ]
  has_many :customers, through: :conversation_members,
                       source: :member, source_type: "Customer",
                       class_name: "Customer"
  has_many :users,     through: :conversation_members,
                       source: :member, source_type: "User",
                       class_name: "User", disable_joins: true
  has_many :messages, dependent: :destroy
  has_many :customer_inboxes, through: :customers

  after_create_commit :broadcast_conversation_creation
  before_save :update_last_activity_at, if: :will_save_change_to_status?


  scope :current_conversations, ->(current_user) {
 joins(:conversation_members).where(conversation_members: { member: current_user }) }

  def event_payload
    {
      id:,
      status:,
      priority:,
      source:,
      title:,
      locale:,
      identifier:,
      inbox_id:,
      last_activity_at:,
      created_at:,
      updated_at:
    }
  end

  def update_last_activity
    touch(:last_activity_at)
  end

  private

  # TODO: Refactor to separate concern
  def broadcast_conversation_creation
    EventBroadcastWorker.perform_async(event_payload.to_json, "conversation.created", connection_tokens)
  end

  def update_last_activity_at
    self.last_activity_at = Time.current
  end

  def connection_tokens
    customer_inboxes.pluck(:connection_token) + users.pluck(:connection_token)
  end
end
