# frozen_string_literal: true

# == Schema Information
#
# Table name: messages
#
#  id                   :uuid             not null, primary key
#  configurations       :jsonb            not null
#  content              :text
#  content_type         :integer          default("text"), not null
#  data                 :jsonb            not null
#  locale               :string
#  sender_type          :string           not null
#  sentiment            :jsonb            not null
#  source               :integer
#  status               :integer          default("sent"), not null
#  visibility           :integer          default("global"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :uuid             not null
#  conversation_id      :uuid             not null
#  external_id          :string
#  external_reply_to_id :string
#  inbox_id             :uuid             not null
#  sender_id            :uuid             not null
#
# Indexes
#
#  index_messages_on_account_id                        (account_id)
#  index_messages_on_account_id_and_external_id        (account_id,external_id)
#  index_messages_on_conversation_id                   (conversation_id)
#  index_messages_on_conversation_id_and_content_type  (conversation_id,content_type)
#  index_messages_on_conversation_id_and_created_at    (conversation_id,created_at)
#  index_messages_on_conversation_id_and_status        (conversation_id,status)
#  index_messages_on_inbox_id                          (inbox_id)
#  index_messages_on_sender                            (sender_type,sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
class Message < ShardRecord
  include UnreadTrackable
  include UsageTrackable

  searchkick word_start: [:content],
             callbacks: :async

  belongs_to :conversation
  belongs_to :inbox
  belongs_to :account
  belongs_to :sender, polymorphic: true
  belongs_to :outbound_channel, polymorphic: true, optional: true

  enum :status, { sent: 0, delivered: 1, read: 2, failed: 3 }
  enum :content_type, { text: 0, activity: 1, csat: 2 }
  enum :visibility, { personal: 0, global: 1 }
  enum :source, { email: 0, facebook_message: 1, whatsapp: 2, instagram_direct_message: 3, api: 4, web_widget: 5, sms: 6, telegram: 7, help_center: 8 }, suffix: true

  has_many :attachments, as: :resource, dependent: :destroy
  has_one :csat_survey_response, class_name: 'Csat::SurveyResponse', dependent: :nullify

  tracks_usage :messages_monthly, enforce: false, decrement_on_destroy: false

  after_create_commit :broadcast_message_creation
  after_create_commit :deliver_contact_form_reply, if: -> { outgoing? && source == "help_center" }
  after_create_commit :process_sla
  after_create_commit :touch_conversation_activity
  after_create_commit :trigger_thank_you_detector, if: :incoming?
  after_create_commit :trigger_ai_agent, if: :incoming?
  after_create_commit :trigger_language_detection, if: :incoming?
  after_update_commit :broadcast_message_update, if: :saved_change_to_status?

  before_save :sanitize_content, if: -> { content.present? && content_changed? }

  def incoming?
    sender_type == "Customer"
  end

  def outgoing?
    sender_type == "User"
  end

  def search_data
    {
      content: ActionController::Base.helpers.strip_tags(content.to_s),
      content_type: content_type,
      visibility: visibility,
      source: source,
      conversation_id: conversation_id,
      conversation_identifier: conversation&.identifier,
      inbox_id: inbox_id,
      sender_type: sender_type,
      sender_name: sender.try(:name) || sender.try(:display_name),
      created_at: created_at,
      account_id: account_id
    }
  end

  def event_payload
    {
      id:,
      content:,
      content_type:,
      status:,
      locale:,
      source:,
      visibility:,
      external_id:,
      data:,
      inbox_id:,
      incoming: incoming?,
      created_at:,
      updated_at:,
      sender: sender&.event_payload,
      conversation: conversation.event_payload
    }
  end

  private

  def sanitize_content
    self.content = ActionController::Base.helpers.sanitize(
      content,
      tags: Parser::MailParser::ALLOWED_TAGS,
      attributes: Parser::MailParser::ALLOWED_ATTRIBUTES
    )
  end

  def deliver_contact_form_reply
    Messages::ContactFormDeliveryWorker.perform_async(id)
  end

  # TODO: Refactor to separate concern
  def broadcast_message_creation
    EventBroadcastWorker.perform_async(event_payload.to_json, "message.created", connection_tokens, account_id)
    
    # Notify agents about the new incoming message
    if incoming?
      conversation.notifiable_agents(exclude_sender: sender).each do |user|
        Notification.create(
          account: account,
          user: user,
          resource: self,
          event: :message_created
        )
      end
    end
  end

  def broadcast_message_update
    EventBroadcastWorker.perform_async(event_payload.to_json, "message.updated", connection_tokens, account_id)
  end

  def connection_tokens
    tokens = account.users.pluck(:connection_token)
    tokens += conversation.customer_inboxes.pluck(:connection_token) unless personal?
    tokens.uniq
  end

  def process_sla
    Sla::EventProcessorWorker.perform_async(conversation_id) if account.feature_enabled?(:sla)
  end

  def touch_conversation_activity
    conversation.update_last_activity
  end

  def trigger_thank_you_detector
    # Only run the detector if the conversation was previously resolved/closed.
    # The actual reopening logic will likely be paused or reverted if it's a thank you.
    # If the app reopens automatically, we revert it in the worker.
    return unless inbox.ai_thank_you_detection?
    
    Ai::ThankYouDetectorWorker.perform_async(id) if account.feature_enabled?(:ai_copilot) || account.feature_enabled?(:ai_agent)
  end

  def trigger_ai_agent
    return unless conversation.ai_active?
    
    if inbox.ai_agent&.active_and_configured?
      Ai::AgentWorker.perform_async(account_id, conversation_id, id, inbox.ai_agent_id)
    else
      # Agent was deactivated while conversation was active. Force handoff.
      conversation.update!(ai_status: :ai_handed_off)
      conversation.send(:auto_assign_agent) if conversation.send(:should_auto_assign?)
    end
  end

  def trigger_language_detection
    return unless sender_type == "Customer"
    return unless sender.locale.blank? || sender.locale == "en"
    return unless conversation.messages.count <= 2

    DetectLanguageWorker.perform_async(account_id, id)
  end
end
