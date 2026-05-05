# frozen_string_literal: true

module Automations
  module Actions
    class AssignAgent < BaseAction
      def call
        require_conversation!

        agent = User.find(params[:agent_id])
        resource.assign!(agent)
      end
    end
  end
end
