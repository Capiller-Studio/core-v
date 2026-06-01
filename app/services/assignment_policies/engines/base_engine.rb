# frozen_string_literal: true

module AssignmentPolicies
  module Engines
    # Base engine with shared logic for all assignment strategies.
    #
    # Provides:
    #   - Finding eligible agents (online, inbox member, team member if applicable)
    #   - Capacity filtering via CapacityChecker
    #   - Notification creation
    #
    # Subclasses must implement #select_agent(eligible_agent_ids) to define
    # the strategy-specific agent selection algorithm.
    #
    class BaseEngine < ApplicationService
      attr_reader :conversation, :policy

      def initialize(conversation:, policy:)
        @conversation = conversation
        @policy = policy
      end

      def call
        eligible_ids = find_eligible_agents
        return if eligible_ids.blank?

        # Apply capacity limits
        eligible_ids = CapacityChecker.call(agent_ids: eligible_ids, policy: policy)
        return if eligible_ids.blank?

        # Priority routing: sort pending conversations before selection
        # (affects load_balanced engine's conversation counts)

        # Strategy-specific selection
        agent = select_agent(eligible_ids)
        return unless agent

        perform_assignment(agent)
      end

      protected

      # Subclasses MUST override this method
      def select_agent(_eligible_agent_ids)
        raise NotImplementedError, "#{self.class}#select_agent must be implemented"
      end

      private

      # Agents must satisfy ALL conditions:
      #   1. Active in Redis (recent heartbeat)
      #   2. AccountUser.availability is :online
      #   3. Member of the inbox
      #   4. Member of the team (if team is assigned to the conversation)
      #
      # Extracted from the original Conversations::RoundRobinAssignment
      def find_eligible_agents
        account = conversation.account
        inbox = conversation.inbox
        team = conversation.team

        # Get user IDs who are active in Redis (recent heartbeat)
        active_user_ids = ::Utilities::ActivityHelpers.available_user_ids(account.id)
        return [] if active_user_ids.blank?

        # Base candidate IDs: inbox agents
        base_agent_ids = inbox.inbox_users.pluck(:user_id).map(&:to_s)

        # If assigned to a team, candidates must also be members of that team
        if team
          team_agent_ids = team.team_users.pluck(:user_id).map(&:to_s)
          base_agent_ids &= team_agent_ids
        end

        return [] if base_agent_ids.blank?

        # Intersect: must be both active AND in the candidate pool
        candidate_ids = active_user_ids & base_agent_ids
        return [] if candidate_ids.blank?

        # Filter: AccountUser.availability must be :online
        AccountUser.where(
          account: account,
          user_id: candidate_ids,
          availability: :online
        ).pluck(:user_id).map(&:to_s)
      end

      def perform_assignment(agent)
        conversation.assign!(agent)
        create_notifications(agent)
      end

      def create_notifications(agent)
        if policy.notify_on_assignment?
          Notification.create(
            account: conversation.account,
            user: agent,
            resource: conversation,
            event: :conversation_assigned
          )
        end

        return unless policy.notify_team_leads? && conversation.team.present?

        conversation.team.team_users.lead.find_each do |tu|
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
end
