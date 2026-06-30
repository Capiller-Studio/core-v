# frozen_string_literal: true

module Channels
  module Concerns
    module ConversationFinder
      extend ActiveSupport::Concern

      def find_or_reopen_conversation(customer, inbox, account)
        recent_conversation = customer.conversations
                                      .where(inbox: inbox, account: account)
                                      .order(created_at: :desc)
                                      .first

        return nil unless recent_conversation

        if recent_conversation.resolved?
          if reopen_window_active?(recent_conversation, inbox)
            recent_conversation.update!(status: :active)
            return recent_conversation
          else
            return nil # Needs a new conversation
          end
        end

        recent_conversation
      end

      private

      def reopen_window_active?(conversation, inbox)
        return false if inbox.reopen_window_seconds.to_i == 0
        return false if conversation.status_changed_at.blank?
        
        (Time.current - conversation.status_changed_at).to_i <= inbox.reopen_window_seconds
      end
    end
  end
end
