# frozen_string_literal: true

module Automations
  module Actions
    class SetPriority < BaseAction
      def call
        require_conversation!

        new_priority = params[:priority]
        raise("Invalid priority: #{new_priority}") unless Conversation.priorities.key?(new_priority)

        resource.update!(priority: new_priority)
      end
    end
  end
end
