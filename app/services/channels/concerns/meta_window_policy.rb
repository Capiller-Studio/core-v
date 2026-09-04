# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

# Shared concern for Meta messaging window policy (24h and 7-day rules).
# Used by FacebookPages::MessageSender, Instagram::MessageSender, and Whatsapp::CloudApi::MessageSender.

module Channels
  module Concerns
    module MetaWindowPolicy
      private

      # High-performance single-column query using the [:conversation_id, :sender_type, :created_at] composite index.
      # Returns the timestamp of the customer's most recent message in this conversation.
      def last_customer_message_at
        return @last_customer_message_at if defined?(@last_customer_message_at)

        conversation = message.conversation
        return @last_customer_message_at = nil unless conversation

        @last_customer_message_at = conversation.messages.
                                      where(sender_type: "Customer").
                                      order(created_at: :desc).
                                      pick(:created_at)
      end

      # Meta's standard 24-hour customer service window.
      # Returns true when the last customer message was sent more than 24 hours ago.
      def outside_24_hours?
        last_at = last_customer_message_at
        last_at.present? && last_at < 24.hours.ago
      end

      # Meta's 7-day HUMAN_AGENT tag window.
      # Returns true when the last customer message was sent more than 7 days ago (or never sent).
      def outside_7_days?
        last_at = last_customer_message_at
        last_at.nil? || last_at < 7.days.ago
      end

      # Checks if the sender is a human support agent (User) vs AI bot or automation.
      def human_agent_sender?
        message.sender_type == "User"
      end
    end
  end
end
