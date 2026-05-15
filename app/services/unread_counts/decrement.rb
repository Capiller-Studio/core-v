# frozen_string_literal: true

module UnreadCounts
  class Decrement < ApplicationService
    attr_accessor :resource, :account_id

    def initialize(resource)
      self.resource = resource
      self.account_id = resource.account_id
    end

    def call
      case resource
      when Message
        decrement_message
      when Mention
        decrement_mention
      end
    end

    private

    def decrement_message
      # Identify all members who might have this as unread
      members = resource.conversation.conversation_members.includes(:member).to_a
      
      if resource.conversation.team_id
        team_users = TeamUser.where(team_id: resource.conversation.team_id).pluck(:user_id)
      else
        team_users = []
      end

      target_members = {}
      members.each { |m| target_members[m.member_id] = m.member }
      
      if team_users.any?
        User.where(id: team_users - target_members.keys).find_each do |user|
          target_members[user.id] = user
        end
      end

      target_members.each do |id, member|
        next if id == resource.sender_id
        
        # Check if the message was likely unread for this member
        membership = resource.conversation.conversation_members.find_by(member: member)
        last_seen = membership&.last_seen_at || resource.conversation.created_at
        
        next unless resource.created_at > last_seen
        
        current_count = RedisUtilities::Helpers.hash_get(conv_key(id), resource.conversation_id).to_i
        next if current_count.zero?

        # Decrement conversation unread count
        RedisUtilities::Helpers.hash_increment(conv_key(id), resource.conversation_id, -1)
        
        # Decrement inbox total unread
        RedisUtilities::Helpers.hash_increment(inbox_key(id), resource.inbox_id, -1)
        
        # If it reached zero, remove from set
        new_count = RedisUtilities::Helpers.hash_get(conv_key(id), resource.conversation_id).to_i
        if new_count <= 0
          RedisUtilities::Helpers.hash_delete(conv_key(id), resource.conversation_id)
          RedisUtilities::Helpers.set_remove(unread_conv_set_key(id), resource.conversation_id)
        end
        
        # Guard against negative inbox counts
        if RedisUtilities::Helpers.hash_get(inbox_key(id), resource.inbox_id).to_i < 0
          RedisUtilities::Helpers.hash_set(inbox_key(id), resource.inbox_id, 0)
        end

        UnreadCounts::Broadcast.call(member: member, account_id: account_id)
      end
    end

    def decrement_mention
      # Only decrement if it was unread
      return if resource.read_at.present?
      
      member = resource.mentioned
      return unless member
      
      current_count = RedisUtilities::Helpers.get(mention_key(member.id)).to_i
      return if current_count.zero?

      RedisUtilities::Helpers.increment(mention_key(member.id), -1)
      
      # Guard against negative counts
      if RedisUtilities::Helpers.get(mention_key(member.id)).to_i < 0
        RedisUtilities::Helpers.set(mention_key(member.id), 0)
      end

      UnreadCounts::Broadcast.call(member: member, account_id: account_id)
    end

    private

    def conv_key(id)
      RedisUtilities::Keys::UNREAD_CONVERSATION_COUNT % { account_id: account_id, member_id: id }
    end

    def unread_conv_set_key(id)
      RedisUtilities::Keys::UNREAD_CONVERSATION_SET % { account_id: account_id, member_id: id }
    end

    def inbox_key(id)
      RedisUtilities::Keys::UNREAD_INBOX_COUNT % { account_id: account_id, member_id: id }
    end

    def mention_key(id)
      RedisUtilities::Keys::UNREAD_MENTION_COUNT % { account_id: account_id, member_id: id }
    end
  end
end
