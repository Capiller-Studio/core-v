# frozen_string_literal: true

module Domains
  class ProvisionSslWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default, retry: 3

    def perform(domain_id)
      domain = Domain.find_by(id: domain_id)
      return unless domain&.dns_verified?
      return if domain.ssl_active?

      domain.update!(ssl_status: :ssl_pending)
    end
  end
end
