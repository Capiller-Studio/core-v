# frozen_string_literal: true

module Auth
  class DomainVerification < ApplicationRecord
    belongs_to :account

    has_secure_token :verification_token

    enum :status, { pending: 0, verified: 1, failed: 2 }

    validates :domain, presence: true, uniqueness: { case_sensitive: false }
    validates :domain, format: {
      with: /\A([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}\z/i,
      message: :invalid_domain_format
    }
    validates :status, presence: true
    validates :check_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_validation :normalize_domain

    scope :pending,  -> { where(status: :pending) }
    scope :verified, -> { where(status: :verified) }
    scope :failed,   -> { where(status: :failed) }

    def dns_txt_expected_value
      "deskbolic-verify=#{verification_token}"
    end

    def dns_txt_record_host
      "_deskbolic-challenge.#{domain}"
    end

    def dns_txt_instruction
      "TXT #{dns_txt_record_host} -> #{dns_txt_expected_value}"
    end

    def mark_verified!
      update!(
        status:          :verified,
        verified_at:     Time.current,
        last_checked_at: Time.current,
        failure_reason:  nil
      )
    end

    def mark_failed!(reason)
      update!(
        status:          :failed,
        last_checked_at: Time.current,
        check_count:     check_count + 1,
        failure_reason:  reason
      )
    end

    private

    def normalize_domain
      self.domain = domain&.to_s&.strip&.downcase
    end
  end
end
