# frozen_string_literal: true

module Conversations
  class RoundRobinAssignment < ApplicationService
    attr_accessor :conversation

    def initialize(conversation:)
      self.conversation = conversation
    end

    def call
      return unless conversation.inbox.auto_assign?

      agent = find_next_agent
      return unless agent

      conversation.assign!(agent)
      create_assignment_notification(agent)
    end

    private

    def find_next_agent
      eligible_agents = find_eligible_agents
      return if eligible_agents.empty?

      pick_round_robin(eligible_agents)
    end

    # Agents must satisfy BOTH conditions:
    # 1. Active in Redis (recent heartbeat within ActivityHelpers margin)
    # 2. AccountUser.availability is :online
    def find_eligible_agents
      account = conversation.account
      inbox = conversation.inbox

      # Get user IDs who are active in Redis (recent heartbeat)
      active_user_ids = Utilities::ActivityHelpers.available_user_ids(account.id)
      return [] if active_user_ids.blank?

      # Get inbox agent IDs
      inbox_agent_ids = inbox.inbox_users.pluck(:user_id).map(&:to_s)
      return [] if inbox_agent_ids.blank?

      # Intersect: must be both active AND an inbox agent
      candidate_ids = active_user_ids & inbox_agent_ids
      return [] if candidate_ids.blank?

      # Filter: AccountUser.availability must be :online
      AccountUser.where(
        account:,
        user_id: candidate_ids,
        availability: :online
      ).pluck(:user_id).map(&:to_s)
    end

    # True round-robin: track last assigned index per inbox in Redis
    def pick_round_robin(agent_ids)
      sorted_ids = agent_ids.sort
      key = round_robin_key

      last_assigned = RedisUtilities::Helpers.get(key)
      next_index = if last_assigned.present?
                     last_index = sorted_ids.index(last_assigned)
                     last_index ? (last_index + 1) % sorted_ids.size : 0
                   else
                     0
                   end

      selected_id = sorted_ids[next_index]
      RedisUtilities::Helpers.set(key, selected_id)

      User.find_by(id: selected_id)
    end

    def round_robin_key
      format(
        RedisUtilities::Keys::INBOX_ROUND_ROBIN,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id
      )
    end

    def create_assignment_notification(agent)
      Notification.create(
        account: conversation.account,
        user: agent,
        resource: conversation,
        event: :conversation_assigned
      )
    end
  end
end
