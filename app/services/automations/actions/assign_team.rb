# frozen_string_literal: true

module Automations
  module Actions
    class AssignTeam < BaseAction
      def call
        require_conversation!

        team = account.teams.find(params[:team_id])

        # Use round-robin to pick an agent from the team, or just assign the team
        # TODO: Implement team-level assignment via ConversationMember when team assignment is built
        # For now, this sets the team association on the conversation
        resource.update!(team: team) if resource.respond_to?(:team=)
      end
    end
  end
end
