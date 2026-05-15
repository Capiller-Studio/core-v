# frozen_string_literal: true

module UnreadCounts
  class Reset < ApplicationService
    def initialize(resource, member)
      @resource = resource
      @member = member
      @account_id = resource.account_id
    end

    def call
      case @resource
      when Conversation
        reset_conversation
      when Mention
        reset_mention
      end
    end

    private

    def reset_conversation
      member_id = @member.id
      conversation_id = @resource.id
      
      current_count = RedisUtilities::Helpers.hash_get(conv_key(member_id), conversation_id).to_i
      return if current_count.zero?

      RedisUtilities::Helpers.hash_delete(conv_key(member_id), conversation_id)
      RedisUtilities::Helpers.set_remove(unread_conv_set_key(member_id), conversation_id)
      
      # Decrement inbox total
      RedisUtilities::Helpers.hash_increment(inbox_key(member_id), @resource.inbox_id, -current_count)
      
      # Guard against negative counts
      if RedisUtilities::Helpers.hash_get(inbox_key(member_id), @resource.inbox_id).to_i < 0
        RedisUtilities::Helpers.hash_set(inbox_key(member_id), @resource.inbox_id, 0)
      end

      broadcast_update(@member)
    end

    def reset_mention
      member_id = @member.id
      RedisUtilities::Helpers.set(mention_key(member_id), 0)
      broadcast_update(@member)
    end

    def conv_key(id)
      RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: @account_id, member_id: id }
    end

    def unread_conv_set_key(id)
      RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: @account_id, member_id: id }
    end

    def inbox_key(id)
      RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: @account_id, member_id: id }
    end

    def mention_key(id)
      RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: @account_id, member_id: id }
    end

    def broadcast_update(member)
      UnreadCounts::Broadcast.call(member: member, account_id: @account_id)
    end
  end
end
