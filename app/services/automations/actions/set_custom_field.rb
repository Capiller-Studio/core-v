# frozen_string_literal: true

module Automations
  module Actions
    class SetCustomField < BaseAction
      def call
        key = params[:key]
        value = params[:value]
        raise "key is required" if key.blank?

        # Writes to the entity's data jsonb column.
        # Works on both Conversation and Customer resources.
        current_data = resource.data || {}
        resource.update!(data: current_data.merge(key => value))
      end
    end
  end
end
