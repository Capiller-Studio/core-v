# frozen_string_literal: true

# == Schema Information
#
# Table name: integrations
#
#  id          :uuid             not null, primary key
#  credentials :jsonb            not null
#  metadata    :jsonb            not null
#  name        :string
#  provider    :integer          not null
#  settings    :jsonb            not null
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#
# Indexes
#
#  index_integrations_on_account_id                 (account_id)
#  index_integrations_on_account_id_and_created_at  (account_id,created_at)
#  index_integrations_on_account_id_and_provider    (account_id,provider)
#  index_integrations_on_account_id_and_status      (account_id,status)
#
class Integration < ShardRecord
  belongs_to :account
  has_many :webhook_deliveries, class_name: "Webhook::Delivery", as: :resource, dependent: :destroy

  enum :provider, { slack: 0, google_translate: 1, webhook: 2 }
  enum :status, { active: 0, disabled: 1 }

  validates :provider, presence: true
  validates :status, presence: true
  validates :name, length: { maximum: 255 }, allow_blank: true
  validates :provider, uniqueness: { scope: :account_id, message: :taken }, unless: :webhook?

  WEBHOOK_EVENTS = %w[
    conversation.created
    conversation.updated
    message.created
    customer.created
    customer.updated
  ].freeze

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
    settings["webhook_url"]
  end

  # HMAC signing secret for webhook deliveries.
  # Stored in credentials["webhook_secret"] when the user configures a webhook integration.
  # If present, all outgoing webhook requests include a Signature header.
  def webhook_secret
    credentials["webhook_secret"]
  end
end
