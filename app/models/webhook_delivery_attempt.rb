# frozen_string_literal: true

class WebhookDeliveryAttempt < ShardRecord
  belongs_to :delivery, class_name: "WebhookDelivery", foreign_key: "webhook_delivery_id"

  validates :attempt_number, presence: true, numericality: { greater_than: 0 }
end
