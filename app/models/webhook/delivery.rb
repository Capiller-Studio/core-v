# frozen_string_literal: true

class Webhook::Delivery < ShardRecord
  belongs_to :account
  belongs_to :resource, polymorphic: true
  has_many :attempts, class_name: "Webhook::DeliveryAttempt", foreign_key: "webhook_delivery_id", dependent: :destroy, inverse_of: :delivery

  enum :status, { pending: 0, successful: 1, failed: 2 }

  validates :account_id, presence: true
  validates :event_name, presence: true
  validates :endpoint_url, presence: true
end
