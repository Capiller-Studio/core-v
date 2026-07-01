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
#  team_id           :uuid
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
  include Trackable
  include CodeGenerator.new(prefix: "CNV", column: :identifier)

  belongs_to :account
  belongs_to :inbox
  belongs_to :team, optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :campaign, optional: true
  belongs_to :outbound_channel, polymorphic: true, optional: true

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
  has_many :csat_survey_responses, class_name: 'Csat::SurveyResponse', dependent: :destroy

  after_create_commit :broadcast_conversation_creation
  after_update_commit :process_sla, if: :saved_change_to_status?
  after_update_commit :dispatch_csat, if: :saved_change_to_status?
  after_update_commit :broadcast_conversation_update
  before_save :update_last_activity_at, if: :will_save_change_to_status?
  after_destroy :cleanup_unread_counts


  scope :current_conversations, ->(current_user) {
    joins(:conversation_members).where(conversation_members: { member: current_user })
  }

  scope :not_assigned_to_user, -> { where(assignee_id: nil) }

  scope :for_team, ->(team) { where(team: team) }
  scope :unassigned_team, -> { where(team_id: nil) }

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
      team_id:,
      last_activity_at:,
      created_at:,
      updated_at:
    }
  end

  def update_last_activity
    # rubocop:disable Rails/SkipsModelValidations
    touch(:last_activity_at)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def mark_as_read_for(user)
    member = conversation_members.find_by(member: user)
    member&.mark_as_read!
  end

  def process_sla
    Sla::EventProcessorWorker.perform_async(id) if account.feature_enabled?(:sla)
  end

  def dispatch_csat
    return unless resolved? && account.feature_enabled?(:csat)
    CsatDispatcherWorker.perform_async(id)
  end

  def notifiable_agents(exclude_sender: nil)
    # 1. Directly assigned participants (excluding customers)
    members = conversation_members.includes(:member).where(member_type: 'User').map(&:member)

    # 2. Team members if assigned to a team
    if team_id.present?
      team_user_ids = TeamUser.where(team_id: team_id).pluck(:user_id)
      team_users = User.where(id: team_user_ids).to_a
      members.concat(team_users)
    end

    # 3. If completely unassigned, notify all users who have access to this inbox
    if assignee_id.nil? && team_id.nil?
      inbox_users = inbox.users.to_a
      inbox_users = account.users.to_a if inbox_users.empty?
      members.concat(inbox_users)
    end

    members.uniq.reject { |u| u == exclude_sender }
  end

  private

  # TODO: Refactor to separate concern
  def broadcast_conversation_creation
    EventBroadcastWorker.perform_async(event_payload.to_json, "conversation.created", connection_tokens, account_id)
    
    notifiable_agents.each do |user|
      Notification.create(
        account: account,
        user: user,
        resource: self,
        event: :conversation_created
      )
    end
  end

  def broadcast_conversation_update
    EventBroadcastWorker.perform_async(event_payload.to_json, "conversation.updated", connection_tokens, account_id)
  end

  def update_last_activity_at
    self.last_activity_at = Time.current
  end

  def connection_tokens
    (customer_inboxes.pluck(:connection_token) + account.users.pluck(:connection_token)).uniq
  end

  def cleanup_unread_counts
    account.users.find_each do |user|
      conv_key = RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: account_id, member_id: user.id }
      set_key = RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: account_id, member_id: user.id }
      inbox_key = RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: account_id, member_id: user.id }
      
      unread_count_for_conv = RedisUtilities::Helpers.hash_get(conv_key, id).to_i
      
      if unread_count_for_conv > 0
        RedisUtilities::Helpers.hash_increment(inbox_key, inbox_id, -unread_count_for_conv)
      end
      
      RedisUtilities::Helpers.hash_delete(conv_key, id)
      RedisUtilities::Helpers.set_remove(set_key, id)
      UnreadCounts::Broadcast.call(member: user, account_id: account_id)
    end
  end
end
