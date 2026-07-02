# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class Activity < ShardRecord
  # --- Associations ---
  belongs_to :account
  belongs_to :trackable, polymorphic: true
  belongs_to :actor, polymorphic: true, optional: true

  # --- Validations ---
  validates :event_key, presence: true

  # --- Scopes ---
  scope :chronological, -> { order(created_at: :asc) }
  scope :latest,        -> { order(created_at: :desc) }

  # High-performance JSONB GIN index queries
  scope :with_changed_attribute, ->(attribute_name) {
    where("object_changes ? :attr", attr: attribute_name.to_s)
  }

  scope :with_attribute_value, ->(attribute_name, value) {
    where("object_snapshot @> ?", { attribute_name => value }.to_json)
  }

  # Soft retention visibility driven by plan limits (preserved physically for compliance)
  scope :retention_visible_for, ->(account) {
    limit_days = account&.current_plan&.limit_for("audit_log_retention_days") || 30
    return all if limit_days == -1

    where("created_at >= ?", limit_days.days.ago)
  }

  after_create_commit :broadcast_activity

  # --- Instance Methods ---

  def translated_description
    I18n.t("activities.#{event_key}", **event_data.symbolize_keys, default: event_key.humanize)
  end

  def broadcast_activity
    # Deskbolic native streams handle Message updates directly, but not Activities.
    return if %w[Message].include?(trackable_type)

    # Prepare payload for ActionCable/AnyCable
    payload = {
      id: id,
      event_key: event_key,
      trackable_id: trackable_id,
      trackable_type: trackable_type,
      description: translated_description,
      actor: actor&.try(:event_payload) || { name: "System" },
      created_at: created_at
    }

    # Broadcast to account-wide and trackable-specific streams
    # This ensures agents see the timeline update live.
    EventBroadcastWorker.perform_async(
      payload.to_json, 
      "activity.created", 
      connection_tokens, 
      account_id
    )
  end

  private

  def connection_tokens
    # If trackable is a conversation, we broadcast to its members
    if trackable.respond_to?(:connection_tokens, true)
      trackable.send(:connection_tokens)
    else
      # Fallback to all account admins/owners
      account.users.pluck(:connection_token)
    end
  end
end
