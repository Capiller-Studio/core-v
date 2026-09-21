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
  include UsageTrackable
  include CodeGenerator.new(prefix: "CNV", column: :identifier)

  searchkick word_start: [:identifier, :title, :customer_name, :customer_email],
             callbacks: :async

  belongs_to :account
  belongs_to :inbox
  belongs_to :team, optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :outbound_channel, polymorphic: true, optional: true

  enum :status, { active: 0, closed: 1, snoozed: 2, resolved: 3 }
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }
  enum :source, {
    email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3,
    api: 4, web_widget: 5, sms: 6, telegram: 7,
    help_center: 8  # Submitted via a Channel::ContactForm on a Help Center portal
  }, suffix: true

  enum :ai_status, { ai_inactive: 0, ai_active: 1, ai_handed_off: 2 }

  has_many :applied_labels, as: :labelable, dependent: :destroy
  has_many :labels, through: :applied_labels

  has_many :conversation_members, dependent: :destroy
  has_many :customers, through: :conversation_members,
                       source: :member, source_type: "Customer",
                       class_name: "Customer"
  has_many :users,     through: :conversation_members,
                       source: :member, source_type: "User",
                       class_name: "User", disable_joins: true
  has_many :messages, dependent: :destroy
  has_many :customer_inboxes, through: :customers
  has_many :csat_survey_responses, class_name: 'Csat::SurveyResponse', dependent: :destroy
  has_one :last_message, -> { order(created_at: :desc) }, class_name: "Message"

  tracks_usage :conversations_monthly, enforce: false, decrement_on_destroy: false

  after_create_commit :broadcast_conversation_creation
  after_create_commit :trigger_ai_classification
  after_update_commit :process_sla, if: :saved_change_to_status?
  after_update_commit :dispatch_csat, if: :saved_change_to_status?
  after_update_commit :record_status_change, if: :saved_change_to_status?
  after_update_commit :record_priority_change, if: :saved_change_to_priority?
  after_update_commit :broadcast_conversation_update
  before_save :update_last_activity_at, if: :will_save_change_to_status?
  before_create :initialize_ai_status
  after_destroy :cleanup_unread_counts


  scope :current_conversations, ->(current_user) {
    joins(:conversation_members).where(conversation_members: { member: current_user })
  }

  scope :not_assigned_to_user, -> { where(assignee_id: nil) }

  scope :for_team, ->(team) { where(team: team) }
  scope :unassigned_team, -> { where(team_id: nil) }

  def search_data
    {
      identifier: identifier,
      title: title,
      status: status,
      priority: priority,
      source: source,
      inbox_id: inbox_id,
      inbox_name: inbox&.name,
      team_id: team_id,
      assignee_id: assignee_id,
      customer_name: customers.filter_map(&:name).join(" "),
      customer_email: customers.filter_map(&:email).join(" "),
      customer_phone: customers.filter_map(&:full_phone_number).join(" "),
      label_titles: labels.map(&:title),
      last_message_preview: last_message_preview,
      created_at: created_at,
      last_activity_at: last_activity_at,
      account_id: account_id
    }
  end

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

  def last_message_preview
    return if last_message&.content.blank?
    return I18n.t('dashboard.csat.survey_message_preview', default: 'Customer satisfaction survey sent') if last_message.csat?

    content_with_spaces = last_message.content.to_s.gsub(/<\/(p|div|li|h[1-6])>|<br\s*\/?>/i, ' ')
    ActionController::Base.helpers.strip_tags(content_with_spaces)&.squish&.truncate(100)
  end

  def last_message_date
    last_message&.created_at&.strftime("%d %b")
  end

  def should_track_changes?
    return false unless persisted?
    
    # Ignore internal timestamps and attributes that have their own dedicated activities
    ignored_attributes = %w[updated_at created_at last_activity_at status_changed_at id status assignee_id team_id]
    meaningful_changes = saved_changes.keys - ignored_attributes
    
    meaningful_changes.any?
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

    # rubocop:disable Performance/ChainArrayAllocation
    members.uniq.reject { |u| u == exclude_sender }
    # rubocop:enable Performance/ChainArrayAllocation
  end

  private

  def initialize_ai_status
    self.ai_status = :ai_active if inbox.ai_agent&.active_and_configured?
  end

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

  def trigger_ai_classification
    Ai::ConversationClassifierWorker.perform_async(id) if inbox.ai_classification?
  end

  def broadcast_conversation_update
    EventBroadcastWorker.perform_async(event_payload.to_json, "conversation.updated", connection_tokens, account_id)
  end

  def update_last_activity_at
    self.last_activity_at = Time.current
  end

  def record_status_change
    Activities::Recorder.call(
      trackable: self,
      event_type: "conversation_#{status}",
      changes: { status: saved_change_to_status },
      actor: Current.user
    )
  end

  def record_priority_change
    Activities::Recorder.call(
      trackable: self,
      event_type: "priority_updated",
      changes: { priority: saved_change_to_priority },
      actor: Current.user
    )
  end

  def connection_tokens
    (customer_inboxes.pluck(:connection_token) + (account&.users&.pluck(:connection_token) || [])).uniq
  end

  def cleanup_unread_counts
    return unless account

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
