# frozen_string_literal: true

module UnreadCounts
  class Broadcast < ApplicationService
    def initialize(member:, account_id:)
      @member = member
      @account_id = account_id
    end

    def call
      tokens = connection_tokens
      return if tokens.empty?

      # Fetch current counts from Redis
      counts = {
        conversations: RedisUtilities::Helpers.hash_get_all(conv_key),
        mentions: RedisUtilities::Helpers.get(mention_key).to_i,
        inboxes: RedisUtilities::Helpers.hash_get_all(inbox_key)
      }

      # Offload to background worker for broadcast and integration dispatch
      EventBroadcastWorker.perform_async(
        counts.to_json,
        "unread_counts.updated",
        tokens,
        @account_id
      )
    end

    private

    def connection_tokens
      case @member
      when User
        [@member.connection_token]
      when Customer
        @member.customer_inboxes.pluck(:connection_token)
      else
        []
      end
    end

    def conv_key
      RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: @account_id, member_id: @member.id }
    end

    def mention_key
      RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: @account_id, member_id: @member.id }
    end

    def inbox_key
      RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: @account_id, member_id: @member.id }
    end
  end
end
