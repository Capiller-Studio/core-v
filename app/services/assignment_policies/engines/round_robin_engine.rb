# frozen_string_literal: true

module AssignmentPolicies
  module Engines
    # Round-robin assignment: rotates evenly across eligible agents.
    #
    # Uses Redis to track the last assigned agent per policy scope,
    # ensuring true round-robin distribution even across process restarts.
    #
    # Mirrors Zendesk's "time elapsed since last assignment" omnichannel
    # and Freshdesk's round-robin IntelliAssign mode.
    #
    class RoundRobinEngine < BaseEngine
      protected

      def select_agent(eligible_agent_ids)
        sorted_ids = eligible_agent_ids.sort
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

      private

      def round_robin_key
        format(
          ::RedisUtilities::Keys::POLICY_ROUND_ROBIN,
          account_id: conversation.account_id,
          policy_id: policy.id
        )
      end
    end
  end
end
