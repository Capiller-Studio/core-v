# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class SystemLog < ApplicationRecord
  # --- Associations ---
  belongs_to :account, optional: true

  # --- Enums ---
  enum :log_level, { info: 0, warn: 1, error: 2, debug: 3 }

  # --- Validations ---
  validates :event_key, presence: true
  validates :log_level, presence: true

  # --- Scopes ---
  scope :chronological, -> { order(created_at: :asc) }
  scope :latest,        -> { order(created_at: :desc) }
  scope :expired,       -> { where("created_at < ?", 6.months.ago) }
  scope :for_event,     ->(key) { where(event_key: key) }

  # Helper to easily log static or formatted payloads
  def self.log_event(event_key, level: :info, account: nil, message: nil, payload: {}, metadata: {})
    create!(
      account:    account,
      event_key:  event_key,
      log_level:  level,
      message:    message,
      payload:    payload,
      metadata:   metadata
    )
  rescue StandardError => e
    Rails.logger.error("SystemLog.log_event failed: #{e.message}")
    nil
  end
end
