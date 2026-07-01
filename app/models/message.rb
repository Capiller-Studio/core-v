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

  after_create_commit :broadcast_message_creation
  after_create_commit :deliver_contact_form_reply, if: -> { outgoing? && source == "help_center" }
  after_create_commit :process_sla
  after_update_commit :broadcast_message_update, if: :saved_change_to_status?

  def incoming?
    sender_type == "Customer"
  end

  def outgoing?
    sender_type == "User"
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

  def deliver_contact_form_reply
    Messages::ContactFormDeliveryWorker.perform_async(id)
  end

  # TODO: Refactor to separate concern
  def broadcast_message_creation
    EventBroadcastWorker.perform_async(event_payload.to_json, "message.created", connection_tokens, account_id)
    
    # Notify agents about the new message
    conversation.notifiable_agents(exclude_sender: sender).each do |user|
      Notification.create(
        account: account,
        user: user,
        resource: self,
        event: :message_created
      )
    end
  end

  def broadcast_message_update
    EventBroadcastWorker.perform_async(event_payload.to_json, "message.updated", connection_tokens, account_id)
  end

  def connection_tokens
    (conversation.customer_inboxes.pluck(:connection_token) + account.users.pluck(:connection_token)).uniq
  end

  def process_sla
    Sla::EventProcessorWorker.perform_async(conversation_id) if account.feature_enabled?(:sla)
  end
end
