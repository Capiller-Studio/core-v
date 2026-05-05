# frozen_string_literal: true

module Automations
  module Actions
    class BaseAction < ApplicationService
      attr_reader :resource, :account, :params

      def initialize(resource:, account:, params:)
        @resource = resource
        @account = account
        @params = params.with_indifferent_access
      end

      def call
        raise NotImplementedError, "Subclasses must implement #call"
      end

      private

      # Helper: ensure the resource is a Conversation (most actions only work on conversations)
      def require_conversation!
        raise "Resource must be a Conversation, got #{resource.class.name}" unless resource.is_a?(Conversation)
      end
    end
  end
end
