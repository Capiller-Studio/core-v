# frozen_string_literal: true

class WebhookDelivery < ShardRecord
  belongs_to :integration
  has_many :attempts, class_name: "WebhookDeliveryAttempt", dependent: :destroy, inverse_of: :delivery

  enum :status, { pending: 0, successful: 1, failed: 2 }

  validates :event_name, presence: true
  validates :endpoint_url, presence: true
end
