# frozen_string_literal: true

class Webhook::Delivery < ShardRecord
  belongs_to :resource, polymorphic: true
  has_many :attempts, class_name: "Webhook::DeliveryAttempt", dependent: :destroy, inverse_of: :delivery

  enum :status, { pending: 0, successful: 1, failed: 2 }

  validates :event_name, presence: true
  validates :endpoint_url, presence: true
end
