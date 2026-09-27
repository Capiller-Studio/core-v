# frozen_string_literal: true

module AssignmentPolicies
  # Drains unassigned conversations for an account/inbox and assigns them
  # to available online agents using the applicable assignment policy.
  #
  # Scalability & Performance:
  #   - Exits early if no agents are active in Redis (0 DB conversation queries).
  #   - Only considers inboxes with auto_assign enabled.
  #   - Verifies conversation.should_auto_assign? (skips active AI conversations).
  #   - Uses row-level locking to prevent race conditions.
  #
  # Triggered when:
  #   - An agent connects in SubscriptionChannel (comes online)
  #   - An agent resolves, closes, or snoozes a conversation (frees capacity)
  #
  class QueueDrainer < ApplicationService
    attr_reader :account_id, :inbox_id

    BATCH_LIMIT = 25

    def initialize(account_id:, inbox_id: nil)
      @account_id = account_id
      @inbox_id = inbox_id
    end

    def call
      account = Account.find_by(id: account_id)
      return unless account

      # Scalability: exit early if no agents are active in Redis for this account
      active_user_ids = ::Utilities::ActivityHelpers.available_user_ids(account.id)
      return if active_user_ids.blank?

      account.with_shard do
        drain_queue(account)
      end
    end

    private

    def drain_queue(account)
      # Inboxes must have auto_assign enabled
      inbox_scope = account.inboxes.auto_assign
      inbox_scope = inbox_scope.where(id: inbox_id) if inbox_id.present?
      auto_assign_inbox_ids = inbox_scope.pluck(:id)
      if auto_assign_inbox_ids.blank?
        update_backlog_status(account)
        return
      end

      # Find active unassigned conversations in auto_assign inboxes, ordered by priority then FIFO
      unassigned_conversations = account.conversations
        .active
        .where(assignee_id: nil, inbox_id: auto_assign_inbox_ids)
        .order(priority: :desc, created_at: :asc)
        .limit(BATCH_LIMIT)

      if unassigned_conversations.empty?
        update_backlog_status(account)
        return
      end

      # Try to assign each unassigned conversation under row lock
      unassigned_conversations.each do |conversation|
        conversation.with_lock do
          next unless conversation.active? && conversation.assignee_id.nil? && conversation.should_auto_assign?

          AssignmentPolicies::Dispatcher.call(conversation: conversation)
        end
      end

      update_backlog_status(account)
    end

    def update_backlog_status(account)
      auto_assign_inbox_ids = account.inboxes.auto_assign.select(:id)
      has_unassigned = account.conversations
        .active
        .exists?(assignee_id: nil, inbox_id: auto_assign_inbox_ids)

      if has_unassigned
        BacklogTracker.mark_backlog_exists(account.id)
      else
        BacklogTracker.mark_backlog_cleared(account.id)
      end
    rescue StandardError => e
      Rails.logger.warn("Failed to update backlog status for account #{account.id}: #{e.message}")
    end
  end
end
