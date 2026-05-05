# frozen_string_literal: true

module Automations
  module Actions
    class Resolve < BaseAction
      def call
        require_conversation!

        resource.update!(status: :resolved)
      end
    end
  end
end
