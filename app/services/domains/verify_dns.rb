# frozen_string_literal: true

require "resolv"

module Domains
  class VerifyDns < ApplicationService
    attr_accessor :domain

    def initialize(domain:)
      self.domain = domain
    end

    def call
      return true if domain.subdomain? # subdomains are always verified (wildcard DNS)

      domain.update!(dns_status: :dns_pending, last_checked_at: Time.current)

      if cname_points_to_target?
        domain.update!(dns_status: :dns_verified, dns_verified_at: Time.current)
        # Trigger SSL provisioning after successful DNS verification
        Domains::ProvisionSslWorker.perform_async(domain.id)
        true
      else
        domain.update!(dns_status: :dns_failed, last_checked_at: Time.current)
        false
      end
    end

    private

    def cname_points_to_target?
      resolver = Resolv::DNS.new
      resources = resolver.getresources(domain.value, Resolv::DNS::Resource::IN::CNAME)
      resources.any? { |r| r.name.to_s.downcase == Domain::CNAME_TARGET }
    rescue Resolv::ResolvError, Resolv::ResolvTimeout
      false
    ensure
      resolver&.close
    end
  end
end
