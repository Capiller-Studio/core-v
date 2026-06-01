# frozen_string_literal: true

module AssignmentPolicies
  # Checks if an agent has capacity to accept a new conversation
  # based on the assignment policy's max_conversations_per_agent limit.
  #
  # Returns the list of agent IDs that still have available capacity.
  #
  class CapacityChecker < ApplicationService
    attr_reader :agent_ids, :policy

    def initialize(agent_ids:, policy:)
      @agent_ids = agent_ids
      @policy = policy
    end

    def call
      return agent_ids if max_limit.nil?
      return [] if agent_ids.blank?

      # Count open (active + snoozed) conversations assigned to each agent
      assigned_counts = Conversation
        .where(assignee_id: agent_ids, status: [:active, :snoozed])
        .group(:assignee_id)
        .count

      # Filter out agents who have reached or exceeded the capacity limit
      agent_ids.select do |agent_id|
        current_count = assigned_counts[agent_id] || 0
        current_count < max_limit
      end
    end

    private

    def max_limit
      policy.max_conversations_per_agent
    end
  end
end
