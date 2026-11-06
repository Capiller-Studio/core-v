# frozen_string_literal: true

require "onelogin/ruby-saml"

module Auth
  module Saml
    class SettingsBuilder < ApplicationService
      attr_reader :config, :host

      def initialize(sso_configuration, host = nil)
        @config = sso_configuration
        @host = host
      end

      def call
        settings = OneLogin::RubySaml::Settings.new

        # IdP Settings
        settings.idp_entity_id               = config.idp_entity_id
        settings.idp_sso_service_url         = config.idp_sso_url
        settings.idp_slo_service_url         = config.idp_slo_url.presence
        settings.idp_cert_multi              = { signing: Array(config.idp_certificates) }

        # SP Settings
        base_url = determine_base_url
        settings.sp_entity_id                        = "#{base_url}/auth/saml/metadata"
        settings.assertion_consumer_service_url      = "#{base_url}/auth/saml/consume"
        settings.single_logout_service_url           = "#{base_url}/auth/saml/logout"
        settings.name_identifier_format              = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

        # Security Constraints
        settings.security[:authn_requests_signed]    = false
        settings.security[:want_assertions_signed]   = true
        settings.security[:want_response_signed]     = false
        settings.security[:signature_method]         = XMLSecurity::Document::RSA_SHA256
        settings.security[:digest_method]            = XMLSecurity::Document::SHA256
        settings.security[:embed_sign]               = false

        settings
      end

      private

      def determine_base_url
        if host.present?
          host_str = host.to_s.strip
          host_str.start_with?("http://", "https://") ? host_str : "https://#{host_str}"
        elsif config.account.present? && config.account.identifier.present?
          app_domain = ENV.fetch("APP_DOMAIN", "rely.capiller.com")
          "https://#{config.account.identifier}.#{app_domain}"
        else
          ENV.fetch("APP_HOST", "https://rely.capiller.com")
        end
      end
    end
  end
end
