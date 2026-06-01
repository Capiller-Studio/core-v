# frozen_string_literal: true

module AssignmentPolicies
  # Handles reassignment when an agent goes offline or becomes idle.
  #
  # Triggered by AccountUser#availability change callbacks.
  # For each conversation assigned to the agent:
  #   1. Resolve the applicable assignment policy
  #   2. If policy.reassign_on_offline is true, unassign and re-dispatch
  #
  # This mimics Zendesk's "auto-reassign when agent goes offline" behavior.
  #
  class ReassignmentService < ApplicationService
    attr_reader :user, :account

    def initialize(user:, account:)
      @user = user
      @account = account
    end

    def call
      assigned_conversations.find_each do |conversation|
        policy = PolicyResolver.call(conversation: conversation)
        next unless policy&.reassign_on_offline?

        conversation.unassign!
        Dispatcher.call(conversation: conversation)
      end
    end

    private

    def assigned_conversations
      Conversation
        .joins(:conversation_members)
        .where(
          conversation_members: {
            member_type: "User",
            member_id: user.id,
            role: :assignee
          }
        )
        .where(account: account, status: [:active, :snoozed])
    end
  end
end
