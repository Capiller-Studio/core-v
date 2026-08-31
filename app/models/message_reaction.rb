# frozen_string_literal: true

class MessageReaction < ShardRecord
  belongs_to :account
  belongs_to :message
  belongs_to :sender, polymorphic: true

  validates :account_id, presence: true
  validates :message_id, presence: true
  validates :sender_id, presence: true
  validates :sender_type, presence: true
  validates :emoji, presence: true, uniqueness: { scope: [:message_id, :sender_type, :sender_id] }

  def event_payload
    {
      id: id,
      message_id: message_id,
      emoji: emoji,
      reaction_name: reaction_name,
      sender_id: sender_id,
      sender_type: sender_type,
      sender_name: sender.try(:name) || sender.try(:display_name) || sender.try(:first_name) || sender_type,
      created_at: created_at
    }
  end
end
