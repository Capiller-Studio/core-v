# frozen_string_literal: true

module Domains
  class CreateSubdomain < ApplicationService
    attr_accessor :account, :slug, :name

    def initialize(account:, slug:, name: nil)
      self.account = account
      self.slug    = slug
      self.name    = name || slug
    end

    def call
      Domain.create!(
        account: account,
        value: slug,           # before_validation callback appends .helpbolic.com
        name: name,
        domain_type: :subdomain,
        status: :active
      )
    end
  end
end
