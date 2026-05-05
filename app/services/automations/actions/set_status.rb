# frozen_string_literal: true

module Automations
  module Actions
    class SetStatus < BaseAction
      def call
        require_conversation!

        new_status = params[:status]
        raise("Invalid status: #{new_status}") unless Conversation.statuses.key?(new_status)

        resource.update!(status: new_status)
      end
    end
  end
end
