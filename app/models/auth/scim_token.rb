# frozen_string_literal: true

require "digest"

module Auth
  class ScimToken < ApplicationRecord
    belongs_to :account

    validates :name, presence: true
    validates :token_digest, presence: true, uniqueness: true

    scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
    scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

    def self.generate_for_account(account, name:, expires_in: nil)
      raw_token = "dbscim_#{SecureRandom.hex(32)}"
      digest = Digest::SHA256.hexdigest(raw_token)
      expires_at = expires_in ? expires_in.from_now : nil

      record = create!(
        account:         account,
        name:            name,
        token_digest:    digest,
        token_last_four: raw_token.last(4),
        expires_at:      expires_at
      )

      [record, raw_token]
    end

    def token_preview
      token_last_four.present? ? "...#{token_last_four}" : "...#{token_digest.last(4)}"
    end

    def self.authenticate(raw_token)
      return nil if raw_token.blank?

      digest = Digest::SHA256.hexdigest(raw_token.to_s.strip)
      token = active.find_by(token_digest: digest)
      return nil unless token

      token.touch_last_used!
      token
    end

    def expired?
      expires_at.present? && expires_at <= Time.current
    end

    def active?
      !expired?
    end

    def touch_last_used!
      update_column(:last_used_at, Time.current)
    end
  end
end
