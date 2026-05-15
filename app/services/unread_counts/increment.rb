# frozen_string_literal: true

module UnreadCounts
  class Increment < ApplicationService
    attr_accessor :resource, :account_id

    def initialize(resource)
      self.resource = resource
      self.account_id = resource.account_id
    end

    def call
      case resource
      when Message
        increment_message
      when Mention
        increment_mention
      end
    end

    private

    def increment_message
      # Identify all members who should see this as unread
      members = []
      
      # 1. Directly assigned participants/watchers/customers
      members += resource.conversation.conversation_members.includes(:member).to_a
      
      # 2. Team members if assigned to a team (Only for Agents)
      if resource.conversation.team_id
        team_users = TeamUser.where(team_id: resource.conversation.team_id).pluck(:user_id)
      else
        team_users = []
      end

      # Collect all target member objects/IDs
      target_members = {} # { id => member_object }
      
      members.each do |m|
        next if m.member_id == resource.sender_id # Don't notify sender
        target_members[m.member_id] = m.member
      end
      
      # Add team members who aren't already members of the conversation
      if team_users.any?
        User.where(id: team_users - target_members.keys - [resource.sender_id]).find_each do |user|
          target_members[user.id] = user
        end
      end
      
      target_members.each do |id, member|
        # Increment conversation unread count
        RedisUtilities::Helpers.hash_increment(conv_key(id), resource.conversation_id, 1)
        
        # Track that this conversation has unreads
        RedisUtilities::Helpers.set_add(unread_conv_set_key(id), resource.conversation_id)
        
        # Increment inbox total unread
        RedisUtilities::Helpers.hash_increment(inbox_key(id), resource.inbox_id, 1)
        
        broadcast_update(member)
      end
    end

    def increment_mention
      member = resource.mentioned
      return unless member
      
      RedisUtilities::Helpers.increment(mention_key(member.id))
      broadcast_update(member)
    end

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

    def broadcast_update(member)
      UnreadCounts::Broadcast.call(member: member, account_id: account_id)
    end
  end
end
