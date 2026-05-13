# frozen_string_literal: true

module Teams
  class AssignmentService < ApplicationService
    attr_reader :conversation, :team, :agent

    def initialize(conversation:, team: nil, agent: nil)
      @conversation = conversation
      @team = team
      @agent = agent
    end

    def call
      validate_assignment!

      ActiveRecord::Base.transaction do
        assign_or_unassign_team
        assign_or_auto_assign_agent
        conversation
      end
    end

    private

    def validate_assignment!
      return unless team

      unless team.account_id == conversation.account_id
        raise ActiveRecord::RecordInvalid, "Team does not belong to the same account as the conversation"
      end

      unless team.active?
        raise ActiveRecord::RecordNotSaved, "Cannot assign conversation to an inactive team"
      end
    end

    def assign_or_unassign_team
      if team
        conversation.assign_team!(team)
        notify_team_leads
      else
        conversation.unassign_team!
      end
    end

    def assign_or_auto_assign_agent
      if agent
        conversation.assign!(agent)
      elsif team&.auto_assign?
        # Reload to ensure the team association is fresh for round-robin
        conversation.reload
        Conversations::RoundRobinAssignment.call(conversation: conversation)
      end
    end

    def notify_team_leads
      return unless team

      team.team_users.lead.find_each do |tu|
        Notification.create(
          account: conversation.account,
          user: tu.user,
          resource: conversation,
          event: :team_assigned
        )
      end
    end
  end
end
