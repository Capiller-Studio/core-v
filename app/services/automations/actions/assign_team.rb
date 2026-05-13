# frozen_string_literal: true

module Automations
  module Actions
    class AssignTeam < BaseAction
      def call
        require_conversation!

        team = account.teams.find(params[:team_id])

        Teams::AssignmentService.call(
          conversation: resource,
          team: team
        )
      end
    end
  end
end
