# frozen_string_literal: true

class Integration < ShardRecord
  belongs_to :account
  has_many :webhook_deliveries, dependent: :destroy

  enum :provider, { slack: 0, google_translate: 1, webhook: 2 }

  validates :provider, presence: true
  validates :provider, uniqueness: { scope: :account_id, message: :taken }

  scope :active, -> { where(active: true) }

  # Webhook & Filtering Extraction Logic
  def subscribed_events
    return [] unless webhook?
    settings["subscribed_events"] || []
  end

  def subscribed_inboxes
    settings["subscribed_inboxes"] || []
  end

  def webhook_url
    return nil unless webhook? || slack?
    settings["url"] || settings["webhook_url"]
  end

  # HMAC signing secret for webhook deliveries.
  # Stored in settings["webhook_secret"] when the user configures a webhook integration.
  # If present, all outgoing webhook requests include a Signature header.
  def webhook_secret
    settings["webhook_secret"]
  end
end
