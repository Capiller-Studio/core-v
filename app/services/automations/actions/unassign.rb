# frozen_string_literal: true

module Automations
  module Actions
    class Unassign < BaseAction
      def call
        require_conversation!

        resource.unassign!
      end
    end
  end
end
