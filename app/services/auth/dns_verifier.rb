# frozen_string_literal: true

require "resolv"

module Auth
  class DnsVerifier < ApplicationService
    attr_reader :verification

    def initialize(domain_verification)
      @verification = domain_verification
    end

    def call
      domain = verification.domain
      expected = verification.dns_txt_expected_value
      host_challenge = verification.dns_txt_record_host

      txt_values = query_txt_records(host_challenge) + query_txt_records(domain)

      matched = txt_values.any? { |val| val.strip == expected.strip }

      if matched
        verification.mark_verified!

        # Add domain to account SSO allowed_email_domains if SSO config exists
        sso_config = verification.account.sso_configuration
        if sso_config.present? && sso_config.allowed_email_domains.exclude?(domain)
          sso_config.allowed_email_domains << domain
          sso_config.save
        end

        Auth::AuditLog.log(
          event_type:  :domain_verified,
          auth_method: :saml,
          status:      :success,
          account:     verification.account,
          metadata:    { domain: domain, verified_at: Time.current }
        )

        { verified: true }
      else
        reason = "DNS TXT record matching '#{expected}' was not found at #{host_challenge} or #{domain}"
        verification.mark_failed!(reason)
        { verified: false, reason: reason }
      end
    rescue StandardError => e
      reason = "DNS resolution failed: #{e.message}"
      verification.mark_failed!(reason)
      { verified: false, reason: reason }
    end

    private

    def query_txt_records(target_host)
      records = []
      Resolv::DNS.open do |dns|
        dns.timeouts = 5
        records = dns.getresources(target_host, Resolv::DNS::Resource::IN::TXT).map do |r|
          r.strings.join
        end
      end
      records
    rescue Resolv::ResolvError, StandardError
      []
    end
  end
end
