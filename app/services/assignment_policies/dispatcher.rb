# frozen_string_literal: true

module AssignmentPolicies
  # Main entry point for the assignment policy system.
  #
  # Called by the Assignable concern's after_create_commit callback.
  # Resolves the applicable policy for the conversation and delegates
  # to the correct engine, or falls back to legacy round-robin for
  # accounts without the feature enabled.
  #
  # Usage:
  #   AssignmentPolicies::Dispatcher.call(conversation: conversation)
  #
  class Dispatcher < ApplicationService
    attr_reader :conversation

    def initialize(conversation:)
      @conversation = conversation
    end

    def call
      # Feature gate: fall back to legacy round-robin
      unless conversation.account.feature_enabled?(:assignment_policies)
        return Conversations::RoundRobinAssignment.call(conversation: conversation)
      end

      policy = PolicyResolver.call(conversation: conversation)

      # No policy configured for this inbox → fall back to legacy round-robin
      unless policy
        return Conversations::RoundRobinAssignment.call(conversation: conversation)
      end

      # Manual strategy → no auto-assign; agents pick from queue
      return if policy.manual?

      # Check business hours — don't assign outside configured hours
      return unless policy.within_business_hours?

      # Check conditions — policy may filter by priority, channel, customer, etc.
      unless policy.conditions.blank? || policy.conditions == {}
        return unless ConditionMatcher.call(policy: policy, conversation: conversation)
      end

      # Delegate to strategy-specific engine
      engine = engine_for(policy.strategy)
      engine.call(conversation: conversation, policy: policy)
    end

    private

    def engine_for(strategy)
      case strategy
      when "round_robin"   then Engines::RoundRobinEngine
      when "load_balanced" then Engines::LoadBalancedEngine
      when "skills_based"  then Engines::SkillsBasedEngine
      else
        raise ArgumentError, "Unknown assignment strategy: #{strategy}"
      end
    end
  end
end
