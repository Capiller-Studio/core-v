# frozen_string_literal: true

module Domains
  class CreateCustomDomain < ApplicationService
    attr_accessor :account, :value, :name

    def initialize(account:, value:, name: nil)
      self.account = account
      self.value   = value
      self.name    = name || value
    end

    def call
      domain = Domain.create!(
        account: account,
        value: value,
        name: name,
        domain_type: :custom,
        status: :active
      )

      # Enqueue background DNS verification
      Domains::DnsVerificationWorker.perform_async(domain.id) if domain.persisted?

      domain
    end
  end
end
