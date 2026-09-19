# frozen_string_literal: true

module Auth
  class AuditLog < ApplicationRecord
    belongs_to :account, optional: true
    belongs_to :user, optional: true

    enum :event_type, {
      login_attempt:         0,
      login_success:         1,
      login_failure:         2,
      logout:                3,
      jit_user_created:      4,
      identity_linked:       5,
      sso_config_changed:    6,
      domain_verified:       7,
      scim_user_created:     8,
      scim_user_updated:     9,
      scim_user_deactivated: 10,
      certificate_warning:   11,
      replay_attack_blocked: 12,
      bypass_login:          13
    }

    enum :auth_method, {
      password: 0,
      saml:     1,
      oidc:     2,
      google:   3,
      facebook: 4,
      github:   5,
      apple:    6,
      scim:     7
    }

    enum :status, { success: 0, failure: 1 }

    validates :event_type, presence: true
    validates :auth_method, presence: true
    validates :status, presence: true

    scope :recent,    -> { order(created_at: :desc) }
    scope :failures,  -> { where(status: :failure) }
    scope :successes, -> { where(status: :success) }
    scope :for_event, ->(type) { where(event_type: type) }
    scope :expired,   -> { where(created_at: ...6.months.ago) }

    def self.log(event_type:, auth_method:, status:, account: nil, user: nil, email: nil, ip_address: nil, user_agent: nil, error_code: nil, error_message: nil, metadata: {})
      create!(
        event_type:    event_type,
        auth_method:   auth_method,
        status:        status,
        account:       account || Current.account,
        user:          user || Current.user,
        email:         email || user&.email || Current.user&.email,
        ip_address:    ip_address || Current.ip_address,
        user_agent:    user_agent || Current.user_agent,
        error_code:    error_code,
        error_message: error_message,
        metadata:      metadata || {}
      )
    rescue StandardError => e
      Rails.logger.error("Auth::AuditLog.log failed: #{e.class} - #{e.message}")
      nil
    end
  end
end
