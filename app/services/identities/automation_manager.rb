# frozen_string_literal: true

module Identities
  class AutomationManager < ApplicationService
    attr_reader :customer, :inbox, :external_id, :account

    def initialize(customer:, inbox:, external_id:)
      @customer = customer
      @inbox = inbox
      @external_id = external_id
      @account = customer.account
    end

    def call
      trigger_custom_identity_syncs
    end

    private

    def trigger_custom_identity_syncs
      # Find all active custom API providers for this account
      account.identity_sources.api.find_each do |source|
        # Check if an identity for this exact source and customer already exists.
        # If not, spawn background sync to retrieve the data.
        unless account.identities.exists?(customer: customer, identity_source: source, identity_type: :custom_api)
          Identities::SyncWorker.perform_async(customer.id, source.id)
        end
      end
    end
  end
end
