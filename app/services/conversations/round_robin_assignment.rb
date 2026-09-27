# frozen_string_literal: true

module Conversations
  class RoundRobinAssignment < ApplicationService
    attr_accessor :conversation

    def initialize(conversation:)
      self.conversation = conversation
    end

    def call
      return unless should_auto_assign?

      agent = find_next_agent
      return unless agent

      conversation.assign!(agent)
    end

    private

    def should_auto_assign?
      team = conversation.team

      # If a team is assigned, defer to the team's auto_assign setting
      if team
        team.auto_assign?
      else
        conversation.inbox.auto_assign?
      end
    end

    def find_next_agent
      eligible_agents = find_eligible_agents
      return if eligible_agents.empty?

      pick_round_robin(eligible_agents)
    end

    # Agents must satisfy:
    # 1. Active in Redis (recent heartbeat within ActivityHelpers margin)
    # 2. Member of the inbox AND team (if team assigned)
    def find_eligible_agents
      account = conversation.account
      inbox = conversation.inbox
      team = conversation.team

      # Base candidate IDs: inbox agents (direct or via assigned teams)
      base_agent_ids = inbox.inbox_users.pluck(:user_id).map(&:to_s)
      if base_agent_ids.blank? && inbox.inbox_teams.any?
        team_ids = inbox.inbox_teams.pluck(:team_id)
        base_agent_ids = TeamUser.where(team_id: team_ids).distinct.pluck(:user_id).map(&:to_s)
      end

      # If assigned to a team, candidates must also be members of that team
      if team
        team_agent_ids = team.team_users.pluck(:user_id).map(&:to_s)
        base_agent_ids &= team_agent_ids
      end

      return [] if base_agent_ids.blank?

      # Get user IDs who are active in Redis (recent heartbeat)
      active_user_ids = ::Utilities::ActivityHelpers.available_user_ids(account.id)
      return [] if active_user_ids.blank?

      candidate_ids = active_user_ids & base_agent_ids
      return [] if candidate_ids.blank?

      # Filter: AccountUser.availability must be :online
      # TODO: Uncomment once UI for agent availability toggle is implemented
      # AccountUser.where(
      #   account: account,
      #   user_id: candidate_ids,
      #   availability: :online
      # ).pluck(:user_id).map(&:to_s)
      candidate_ids
    end

    # True round-robin: track last assigned index per scope in Redis.
    # When team is present, use a team-scoped key to avoid collisions
    # between teams that share the same inbox.
    def pick_round_robin(agent_ids)
      sorted_ids = agent_ids.sort
      key = round_robin_key

      last_assigned = ::RedisUtilities::Helpers.get(key)
      next_index = if last_assigned.present?
                     last_index = sorted_ids.index(last_assigned)
                     last_index ? (last_index + 1) % sorted_ids.size : 0
      else
                     0
      end

      selected_id = sorted_ids[next_index]
      ::RedisUtilities::Helpers.set(key, selected_id)

      User.find_by(id: selected_id)
    end

    def round_robin_key
      team = conversation.team

      if team
        format(
          ::RedisUtilities::Keys::TEAM_ROUND_ROBIN,
          account_id: conversation.account_id,
          team_id: team.id
        )
      else
        format(
          ::RedisUtilities::Keys::INBOX_ROUND_ROBIN,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        )
      end
    end
  end
end
