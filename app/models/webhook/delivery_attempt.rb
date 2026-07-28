# frozen_string_literal: true

class Webhook::DeliveryAttempt < ShardRecord
  belongs_to :delivery, class_name: "Webhook::Delivery", foreign_key: "webhook_delivery_id", inverse_of: :attempts

  validates :attempt_number, presence: true, numericality: { greater_than: 0 }
end
