# frozen_string_literal: true

class CustomerDevice < ShardRecord
  belongs_to :account
  belongs_to :customer
  belongs_to :inbox
  belongs_to :customer_inbox

  enum :platform, { ios: 0, android: 1 }
  enum :push_provider, { apns: 0, fcm: 1 }
  enum :status, { active: 0, invalid_token: 1 }

  validates :push_token, presence: true, uniqueness: { scope: :inbox_id }

  scope :active, -> { where(status: :active) }

  def invalidate!(reason = nil)
    update_columns(
      status: self.class.statuses[:invalid_token],
      data: data.merge("last_error" => reason.to_s, "invalidated_at" => Time.current.iso8601)
    )
  end
end
