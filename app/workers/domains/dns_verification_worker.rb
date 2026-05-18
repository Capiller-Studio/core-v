# frozen_string_literal: true

module Domains
  class DnsVerificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 5

    def perform(domain_id)
      domain = Domain.find_by(id: domain_id)
      return unless domain&.custom?
      return if domain.dns_verified?

      Domains::VerifyDns.call(domain: domain)
    end
  end
end
