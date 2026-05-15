# frozen_string_literal: true

module UnreadCounts
  class Current < ApplicationService
    attr_accessor :member, :account_id

    def initialize(member:, account_id:)
      self.member = member
      self.account_id = account_id
    end

    def call
      {
        conversations: RedisUtilities::Helpers.hash_get_all(conv_key),
        mentions: RedisUtilities::Helpers.get(mention_key).to_i,
        inboxes: RedisUtilities::Helpers.hash_get_all(inbox_key),
        unread_conversation_ids: RedisUtilities::Helpers.set_members(set_key)
      }
    end

    private

    def conv_key
      RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: account_id, member_id: member.id }
    end

    def set_key
      RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: account_id, member_id: member.id }
    end

    def inbox_key
      RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: account_id, member_id: member.id }
    end

    def mention_key
      RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: account_id, member_id: member.id }
    end
  end
end
