# frozen_string_literal: true

module AssignmentPolicies
  # Finds the first active assignment policy that applies to a conversation.
  #
  # Resolution order:
  #   1. Policies explicitly scoped to the conversation's inbox (via AssignmentPolicyInbox)
  #   2. Among matching policies, ordered by position (lower = higher priority)
  #   3. First match wins (like automations — only one policy fires)
  #
  # Returns nil if no policy is configured for the conversation's inbox.
  #
  class PolicyResolver < ApplicationService
    attr_reader :conversation

    def initialize(conversation:)
      @conversation = conversation
    end

    def call
      find_policy_for_inbox
    end

    private

    def find_policy_for_inbox
      AssignmentPolicy
        .for_inbox(conversation.inbox)
        .first
    end
  end
end
