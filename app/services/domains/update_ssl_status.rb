# frozen_string_literal: true

module Domains
  class UpdateSslStatus < ApplicationService
    attr_accessor :domain, :status, :expires_at

    def initialize(domain:, status:, expires_at: nil)
      self.domain     = domain
      self.status     = status
      self.expires_at = expires_at
    end

    def call
      attrs = { ssl_status: status, last_checked_at: Time.current }
      attrs[:ssl_added_at]   = Time.current if status.to_s == "ssl_active" && domain.ssl_added_at.nil?
      attrs[:ssl_expires_at] = expires_at   if expires_at.present?

      domain.update!(attrs)
    end
  end
end
