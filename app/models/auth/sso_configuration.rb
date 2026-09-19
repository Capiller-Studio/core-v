# frozen_string_literal: true

module Auth
  class SsoConfiguration < ApplicationRecord
    belongs_to :account

    encrypts :oidc_client_secret

    enum :protocol, { saml: 0, oidc: 1 }
    enum :provider_type, {
      custom: 0,
      okta: 1,
      azure_ad: 2,
      google_workspace: 3,
      onelogin: 4,
      ping_identity: 5
    }
    enum :status, { inactive: 0, active: 1, test_mode: 2 }

    validates :protocol, presence: true
    validates :provider_type, presence: true
    validates :status, presence: true
    validates :account_id, uniqueness: true

    # SAML validations (enforced when SSO is active or test_mode)
    validates :idp_entity_id, presence: true, if: :saml_enabled?
    validates :idp_sso_url, presence: true, if: :saml_enabled?
    validates :idp_sso_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: :invalid_url }, allow_blank: true
    validates :idp_slo_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: :invalid_url }, allow_blank: true
    validates :idp_metadata_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: :invalid_url }, allow_blank: true
    validate :validate_idp_certificates, if: :saml_enabled?

    # OIDC validations (enforced when SSO is active or test_mode)
    validates :oidc_issuer, presence: true, if: :oidc_enabled?
    validates :oidc_issuer, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: :invalid_url }, allow_blank: true
    validates :oidc_client_id, presence: true, if: :oidc_enabled?
    validates :oidc_client_secret, presence: true, if: -> { oidc_enabled? && oidc_client_secret.blank? && new_record? }

    # Allowed email domains (enforced when SSO is active or test_mode)
    validate :validate_allowed_email_domains, if: :sso_enabled?

    # Safeguard to prevent accidental admin lockout
    validate :validate_enforce_sso_safeguard

    # Session timeout in seconds (min 1 minute = 60s, max 30 days = 2_592_000s)
    validates :session_timeout_seconds, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 60,
      less_than_or_equal_to: 2_592_000,
      allow_nil: true
    }

    before_validation :normalize_email_domains
    before_validation :clean_certificates
    before_save :compute_certificate_expires_at
    after_commit :clear_domain_cache

    def default_role
      return nil if default_role_id.blank?

      account.with_shard { Access::Role.find_by(id: default_role_id) }
    end

    def sso_enabled?
      active? || test_mode?
    end

    def saml_enabled?
      saml? && sso_enabled?
    end

    def oidc_enabled?
      oidc? && sso_enabled?
    end

    def session_timeout_hours
      seconds = read_attribute(:session_timeout_seconds)
      seconds ? (seconds / 3600.0).round(1) : nil
    end

    def session_timeout_hours=(hours)
      write_attribute(:session_timeout_seconds, hours.present? ? (hours.to_f * 3600).to_i : nil)
    end

    def idp_certificate_raw
      @idp_certificate_raw || Array(idp_certificates).join("\n\n")
    end

    def idp_certificate_raw=(raw_text)
      @idp_certificate_raw = raw_text
      self.idp_certificates = raw_text.to_s.split(/(?=-----BEGIN CERTIFICATE-----)/).map(&:strip).compact_blank
    end

    def allowed_email_domains_raw
      @allowed_email_domains_raw || Array(allowed_email_domains).join(", ")
    end

    def allowed_email_domains_raw=(raw_text)
      @allowed_email_domains_raw = raw_text
      self.allowed_email_domains = raw_text.to_s.split(/[,\s\n\r]+/).map(&:strip).compact_blank
    end

    def domain_matches?(email_or_domain)
      return false if email_or_domain.blank?

      domain = email_or_domain.include?("@") ? email_or_domain.split("@").last : email_or_domain
      allowed_email_domains.include?(domain.downcase.strip)
    end

    def certificate_expiring_soon?(days: 30)
      certificate_expires_at.present? && certificate_expires_at < days.days.from_now
    end

    def certificate_expired?
      certificate_expires_at.present? && certificate_expires_at <= Time.current
    end

    def parsed_certificates
      Array(idp_certificates).filter_map do |cert_str|
        OpenSSL::X509::Certificate.new(normalize_pem(cert_str))
      rescue OpenSSL::X509::CertificateError
        nil
      end
    end

    def certificate_fingerprints(digest: OpenSSL::Digest::SHA256)
      parsed_certificates.map { |cert| digest.hexdigest(cert.to_der).scan(/../).join(":") }
    end

    private

    def normalize_email_domains
      return if allowed_email_domains.blank?

      domains = Array(allowed_email_domains).map { |d| d.to_s.strip.downcase }
      domains.compact_blank!
      domains.uniq!
      self.allowed_email_domains = domains
    end

    def clean_certificates
      return if idp_certificates.blank?

      certs = Array(idp_certificates).map { |c| normalize_pem(c) }
      certs.compact_blank!
      certs.uniq!
      self.idp_certificates = certs
    end

    def normalize_pem(cert_str)
      return "" if cert_str.blank?

      clean = cert_str.to_s.strip
      return clean if clean.start_with?("-----BEGIN CERTIFICATE-----")

      # Re-wrap raw base64 string
      raw = clean.gsub(/[\r\n\s]+/, "")
      "-----BEGIN CERTIFICATE-----\n#{raw.scan(/.{1,64}/).join("\n")}\n-----END CERTIFICATE-----"
    end

    def validate_idp_certificates
      if idp_certificates.blank? || idp_certificates.empty?
        errors.add(:idp_certificates, :blank)
        return
      end

      idp_certificates.each_with_index do |cert_str, idx|
        OpenSSL::X509::Certificate.new(normalize_pem(cert_str))
      rescue OpenSSL::X509::CertificateError
        errors.add(:idp_certificates, "item ##{idx + 1} is not a valid X.509 PEM certificate")
      end
    end

    def validate_allowed_email_domains
      if allowed_email_domains.blank? || allowed_email_domains.empty?
        errors.add(:allowed_email_domains, :blank)
        return
      end

      domain_regex = /\A([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}\z/i
      allowed_email_domains.each do |domain|
        unless domain.match?(domain_regex)
          errors.add(:allowed_email_domains, "'#{domain}' is not a valid domain name")
        end
      end
    end

    def validate_enforce_sso_safeguard
      return unless enforce_sso?

      unless active?
        errors.add(:enforce_sso, "can only be enabled when SSO status is Active")
      end

      if allowed_email_domains.blank?
        errors.add(:enforce_sso, "requires at least one allowed corporate email domain")
      end
    end

    def compute_certificate_expires_at
      return unless saml?

      expiries = parsed_certificates.map(&:not_after)
      self.certificate_expires_at = expiries.min if expiries.any?
    end

    def clear_domain_cache
      domains = Array(allowed_email_domains)
      domains += Array(allowed_email_domains_previously_was) if respond_to?(:allowed_email_domains_previously_was)
      domains.compact!
      domains.uniq!
      domains.each do |domain|
        Auth::DomainLookupService.clear_cache(domain)
      end
    end
  end
end
