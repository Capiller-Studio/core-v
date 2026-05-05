# frozen_string_literal: true

module Automations
  module Actions
    class MuteConversation < BaseAction
      def call
        require_conversation!

        # Muting prevents notifications for this conversation.
        # Stored as a flag in configurations since there's no muted column.
        resource.update!(
          configurations: resource.configurations.merge("muted" => true)
        )
      end
    end
  end
end
