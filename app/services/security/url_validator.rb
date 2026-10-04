# frozen_string_literal: true

require "resolv"
require "ipaddr"
require "uri"

module Security
  class UrlValidator
    class InsecureUrlError < StandardError; end

    BLOCKED_HOSTNAMES = %w[
      localhost
      127.0.0.1
      0.0.0.0
      ::1
    ].freeze

    BLOCKED_DOMAIN_SUFFIXES = %w[
      .local
      .internal
      .lan
      .home.arpa
    ].freeze

    class << self
      def valid_url?(url, allow_local: false)
        validate(url, allow_local: allow_local)[:valid]
      end

      def validate(url, allow_local: false)
        return { valid: false, error: I18n.t("security.url_validator.cannot_be_blank", default: "cannot be blank") } if url.to_s.strip.blank?

        raw_url = url.to_s.strip
        unless raw_url.match?(%r{\Ahttps?://}i)
          return { valid: false, error: I18n.t("security.url_validator.invalid_format", default: "must be a valid URL format") }
        end

        # Replace Liquid template variables like {{customer.id}} with safe placeholder for URI parsing
        parseable_url = raw_url.gsub(/\{\{.*?\}\}/, "placeholder").gsub(/\{.*?\}/, "placeholder")

        begin
          uri = URI.parse(parseable_url)
        rescue URI::InvalidURIError
          return { valid: false, error: I18n.t("security.url_validator.invalid_format", default: "must be a valid URL format") }
        end

        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          return { valid: false, error: I18n.t("security.url_validator.http_or_https_required", default: "must be an HTTP or HTTPS URL") }
        end

        host = uri.host.to_s.strip.downcase
        return { valid: false, error: I18n.t("security.url_validator.missing_host", default: "must contain a valid host") } if host.blank?

        # Allow local testing in test/development when specifically permitted
        if allow_local && (Rails.env.development? || Rails.env.test?)
          return { valid: true, uri: uri }
        end

        # Reject explicitly blocked hostnames and domain suffixes
        if BLOCKED_HOSTNAMES.include?(host) || BLOCKED_DOMAIN_SUFFIXES.any? { |suffix| host.end_with?(suffix) }
          return { valid: false, error: I18n.t("security.url_validator.localhost_blocked", default: "cannot point to localhost or internal network spaces") }
        end

        # In test environment, standard RFC test/mock domains are valid without live DNS resolution
        if Rails.env.test? && (host == "example.com" || host.end_with?(".example.com") || host.end_with?(".example") || host.end_with?(".test") || host.end_with?(".invalid"))
          return { valid: true, uri: uri }
        end

        # Resolve IP addresses and inspect each for private/loopback/link-local ranges
        begin
          ip_addresses = Resolv.getaddresses(host)
          if ip_addresses.empty?
            begin
              ip = IPAddr.new(host)
              if private_ip?(ip)
                return { valid: false, error: I18n.t("security.url_validator.private_ip_blocked", default: "cannot point to internal or private IP addresses") }
              end
            rescue IPAddr::InvalidAddressError
              return { valid: false, error: I18n.t("security.url_validator.resolution_failed", default: "domain could not be resolved") }
            end
          else
            ip_addresses.each do |ip_str|
              ip = IPAddr.new(ip_str)
              if private_ip?(ip)
                return { valid: false, error: I18n.t("security.url_validator.private_ip_blocked", default: "cannot point to internal or private IP addresses") }
              end
            end
          end
        rescue Resolv::ResolvError
          return { valid: false, error: I18n.t("security.url_validator.resolution_failed", default: "domain could not be resolved") }
        rescue StandardError => e
          return { valid: false, error: I18n.t("security.url_validator.validation_failed", message: e.message, default: "could not be validated: %{message}") }
        end

        { valid: true, uri: uri }
      end

      def private_ip?(ip)
        ip.loopback? || ip.private? || ip.link_local? || ip == IPAddr.new("0.0.0.0") || ip == IPAddr.new("::")
      rescue StandardError
        false
      end
    end
  end
end
