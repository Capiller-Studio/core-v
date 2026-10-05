# frozen_string_literal: true

module Automations
  module Actions
    class AssignAgent < BaseAction
      def call
        require_conversation!

        # Scoped to the account so a crafted action can never assign a user from another tenant.
        agent = account.users.find(params[:agent_id])
        resource.assign!(agent)
      end
    end
  end
end
