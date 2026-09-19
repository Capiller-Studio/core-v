# frozen_string_literal: true

module Auth
  class DomainLookupService < ApplicationService
    CACHE_TTL = 24.hours.to_i

    attr_reader :raw_input, :domain

    def initialize(email_or_domain)
      @raw_input = email_or_domain.to_s.strip.downcase
      @domain    = @raw_input.include?("@") ? @raw_input.split("@").last : @raw_input
    end

    def call
      return { sso_required: false } if domain.blank?

      cache_key = RedisUtilities::Keys::AUTH_DOMAIN_SSO % { domain: domain }
      cached = RedisUtilities::Helpers.get(cache_key)

      if cached.present?
        return { sso_required: false } if cached == "none"

        begin
          return JSON.parse(cached, symbolize_names: true)
        rescue JSON::ParserError
          # Fall through to db query
        end
      end

      # Database lookup
      config = Auth::SsoConfiguration
        .joins(:account)
        .where(status: [:active, :test_mode])
        .where("auth_sso_configurations.allowed_email_domains @> ?", [domain].to_json)
        .first

      if config.present?
        result = {
          sso_required:       config.active?,
          test_mode:          config.test_mode?,
          account_id:         config.account_id,
          account_name:       config.account.name,
          account_identifier: config.account.identifier,
          protocol:           config.protocol,
          provider_type:      config.provider_type,
          enforce_sso:        config.enforce_sso?
        }
        RedisUtilities::Helpers.set(cache_key, result.to_json, expiry: CACHE_TTL)
        result
      else
        RedisUtilities::Helpers.set(cache_key, "none", expiry: CACHE_TTL)
        { sso_required: false }
      end
    end

    def self.clear_cache(domain)
      return if domain.blank?

      cache_key = RedisUtilities::Keys::AUTH_DOMAIN_SSO % { domain: domain.downcase.strip }
      RedisUtilities::Helpers.delete(cache_key)
    end
  end
end
