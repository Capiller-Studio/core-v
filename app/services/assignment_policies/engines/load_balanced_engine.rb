# frozen_string_literal: true

module AssignmentPolicies
  module Engines
    # Load-balanced assignment: assigns to the agent with the fewest open conversations.
    #
    # Mirrors Freshdesk's "load-balanced" IntelliAssign mode and
    # Intercom's "Balanced Assignment" workload management.
    #
    # Tie-breaking: when multiple agents have the same conversation count,
    # the agent who was assigned least recently gets priority (earliest last assignment).
    #
    class LoadBalancedEngine < BaseEngine
      protected

      def select_agent(eligible_agent_ids)
        return User.find_by(id: eligible_agent_ids.first) if eligible_agent_ids.size == 1

        # Count open (active + snoozed) conversations assigned to each agent
        counts = ConversationMember
          .where(member_type: "User", member_id: eligible_agent_ids, role: :assignee)
          .joins(:conversation)
          .merge(Conversation.where(status: [:active, :snoozed]))
          .group(:member_id)
          .count

        # Find last assignment time for tie-breaking
        last_assignments = ConversationMember
          .where(member_type: "User", member_id: eligible_agent_ids, role: :assignee)
          .group(:member_id)
          .maximum(:updated_at)

        # Select agent with lowest conversation count
        # Tie-break by earliest last assignment (longest idle)
        selected_id = eligible_agent_ids.min_by do |id|
          count = counts[id] || 0
          last_assigned = last_assignments[id] || Time.at(0)
          [count, last_assigned]
        end

        User.find_by(id: selected_id)
      end
    end
  end
end
