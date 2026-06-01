# frozen_string_literal: true

module AssignmentPolicies
  module Engines
    # Skills-based assignment: routes to the most qualified agent
    # based on skill matching, then load-balances among matches.
    #
    # Mirrors Zendesk's Skills-Based Routing and Freshdesk's
    # skill-based IntelliAssign mode.
    #
    # Flow:
    #   1. Determine required skills from policy configurations
    #   2. Filter eligible agents to those who have the required skills
    #   3. Apply skill_match_mode ("all" or "any") from configurations
    #   4. Among matching agents, select the one with fewest open conversations
    #   5. If no agent matches all skills, fallback to best partial match
    #
    class SkillsBasedEngine < BaseEngine
      protected

      def select_agent(eligible_agent_ids)
        required_skill_ids = policy.configurations["required_skill_ids"] || []

        # If no skills configured, fall back to load-balanced selection
        if required_skill_ids.blank?
          return load_balanced_select(eligible_agent_ids)
        end

        match_mode = policy.configurations["skill_match_mode"] || "all"

        # Find agents with matching skills
        matched_agents = find_skilled_agents(eligible_agent_ids, required_skill_ids, match_mode)

        if matched_agents.present?
          load_balanced_select(matched_agents)
        else
          # Fallback: try partial match or fall back to any eligible agent
          handle_fallback(eligible_agent_ids, required_skill_ids)
        end
      end

      private

      # Find agents who have the required skills based on match mode
      def find_skilled_agents(agent_ids, required_skill_ids, match_mode)
        user_skills = UserSkill
          .where(user_id: agent_ids, skill_id: required_skill_ids)
          .group(:user_id)

        case match_mode
        when "all"
          # Agent must have ALL required skills
          user_skills
            .having("COUNT(DISTINCT skill_id) = ?", required_skill_ids.size)
            .pluck(:user_id)
            .map(&:to_s)
        when "any"
          # Agent must have at least ONE required skill
          user_skills
            .pluck(:user_id)
            .uniq
            .map(&:to_s)
        else
          []
        end
      end

      # When no agent matches all skills, try best partial match
      def handle_fallback(agent_ids, required_skill_ids)
        fallback_strategy = policy.configurations["fallback_strategy"] || "best_match"

        case fallback_strategy
        when "best_match"
          # Find agents with the most matching skills
          skill_counts = UserSkill
            .where(user_id: agent_ids, skill_id: required_skill_ids)
            .group(:user_id)
            .count

          return load_balanced_select(agent_ids) if skill_counts.empty?

          # Sort by skill count descending, pick agents with highest match
          max_skills = skill_counts.values.max
          best_matches = skill_counts.select { |_id, count| count == max_skills }.keys.map(&:to_s)

          load_balanced_select(best_matches)
        when "round_robin"
          # Fall back to round-robin among all eligible agents
          RoundRobinEngine.new(conversation: conversation, policy: policy)
                          .send(:select_agent, agent_ids)
        else
          # Default: load-balanced among all eligible
          load_balanced_select(agent_ids)
        end
      end

      # Load-balanced selection: pick agent with fewest open conversations
      def load_balanced_select(agent_ids)
        return User.find_by(id: agent_ids.first) if agent_ids.size == 1

        counts = ConversationMember
          .where(member_type: "User", member_id: agent_ids, role: :assignee)
          .joins(:conversation)
          .merge(Conversation.where(status: [:active, :snoozed]))
          .group(:member_id)
          .count

        selected_id = agent_ids.min_by { |id| counts[id] || 0 }
        User.find_by(id: selected_id)
      end
    end
  end
end
