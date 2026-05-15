# frozen_string_literal: true

module UnreadCounts
  class Sync < ApplicationService
    def initialize(member:, account_id:)
      @member = member
      @account_id = account_id
    end

    def call
      sync_conversations
      sync_mentions
      UnreadCounts::Broadcast.call(member: @member, account_id: @account_id)
    end

    private

    def sync_conversations
      # Find all conversations the member has access to
      direct_memberships = ConversationMember.where(member: @member, account_id: @account_id).index_by(&:conversation_id)
      
      if @member.is_a?(User)
        team_ids = TeamUser.where(user: @member).pluck(:team_id)
        team_conversation_ids = Conversation.where(team_id: team_ids, account_id: @account_id).pluck(:id)
      else
        team_conversation_ids = []
      end
      
      all_conversation_ids = (direct_memberships.keys + team_conversation_ids).uniq
      
      # Clear existing counts
      RedisUtilities::Helpers.delete(conv_key)
      RedisUtilities::Helpers.delete(set_key)
      RedisUtilities::Helpers.delete(inbox_key)

      # Batch process conversations
      Conversation.where(id: all_conversation_ids).find_each do |conversation|
        membership = direct_memberships[conversation.id]
        last_seen = membership&.last_seen_at || conversation.created_at
        
        unread_count = conversation.messages
                                   .where("created_at > ?", last_seen)
                                   .where.not(sender_id: @member.id)
                                   .count
        
        if unread_count > 0
          RedisUtilities::Helpers.hash_set(conv_key, conversation.id, unread_count)
          RedisUtilities::Helpers.set_add(set_key, conversation.id)
          RedisUtilities::Helpers.hash_increment(inbox_key, conversation.inbox_id, unread_count)
        end
      end
    end

    def sync_mentions
      mention_count = Mention.where(mentioned: @member, account_id: @account_id, read_at: nil).count
      RedisUtilities::Helpers.set(mention_key, mention_count)
    end

    def conv_key
      RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: @account_id, member_id: @member.id }
    end

    def set_key
      RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: @account_id, member_id: @member.id }
    end

    def inbox_key
      RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: @account_id, member_id: @member.id }
    end

    def mention_key
      RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: @account_id, member_id: @member.id }
    end
  end
end
