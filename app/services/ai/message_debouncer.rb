# frozen_string_literal: true

module Ai
  # Buffers and debounces rapid incoming customer messages across chat channels
  # (Web Widget, WhatsApp, Messenger, SMS) so the AI agent processes the complete
  # bundled user intent in a single inference call instead of fragmenting into multiple replies.
  class MessageDebouncer < ApplicationService
    LIVE_CHAT_DEBOUNCE_DELAY = 3.5.seconds
    EMAIL_DEBOUNCE_DELAY = 0.seconds

    class << self
      def buffer_key(account_id, conversation_id)
        format(RedisUtilities::Keys::AI_MESSAGE_BUFFER, account_id: account_id, conversation_id: conversation_id)
      end

      def timer_key(account_id, conversation_id)
        format(RedisUtilities::Keys::AI_DEBOUNCE_TIMER, account_id: account_id, conversation_id: conversation_id)
      end

      def debounce_delay_for(message)
        message.email_source? ? EMAIL_DEBOUNCE_DELAY : LIVE_CHAT_DEBOUNCE_DELAY
      end

      def enqueue(message)
        conversation = message.conversation
        return unless conversation.ai_active?

        inbox = message.inbox
        ai_agent = inbox.ai_agent
        return unless ai_agent&.active_and_configured?

        b_key = buffer_key(message.account_id, conversation.id)
        t_key = timer_key(message.account_id, conversation.id)

        # 1. Append message ID to conversation buffer
        RedisUtilities::Helpers.push(b_key, message.id.to_s)

        # 2. Update the debounce timestamp token (sliding window)
        token = Time.current.to_f.to_s
        RedisUtilities::Helpers.set(t_key, token, overwrite: true, expiry: 60)

        delay = debounce_delay_for(message)

        if delay > 0
          Ai::AgentWorker.perform_in(delay, message.account_id, conversation.id, ai_agent.id, token)
        else
          Ai::AgentWorker.perform_async(message.account_id, conversation.id, ai_agent.id, token)
        end
      rescue StandardError => e
        Rails.logger.error("[Ai::MessageDebouncer] Failed to enqueue message ##{message.id}: #{e.message}")
        # Fallback to immediate execution if Redis fails
        Ai::AgentWorker.perform_async(message.account_id, conversation.id, ai_agent.id)
      end

      # Returns true if this worker instance matches the latest debounce token in Redis
      def ready_to_process?(account_id, conversation_id, token)
        return true if token.blank? # Legacy or immediate fallback

        current_token = RedisUtilities::Helpers.get(timer_key(account_id, conversation_id))
        current_token.present? && current_token == token
      rescue StandardError => e
        Rails.logger.warn("[Ai::MessageDebouncer] Failed to check token for conversation ##{conversation_id}: #{e.message}")
        true
      end

      # Atomically fetches and deletes message IDs from the buffer, returning Message records in exact arrival order
      def drain_messages(account, conversation)
        b_key = buffer_key(account.id, conversation.id)
        t_key = timer_key(account.id, conversation.id)

        message_ids = RedisUtilities::Helpers.subset(b_key, from: 0, to: -1)
        RedisUtilities::Helpers.delete(b_key)
        RedisUtilities::Helpers.delete(t_key)

        return [] if message_ids.blank?

        account.with_shard do
          records = conversation.messages.where(id: message_ids).index_by(&:id)
          message_ids.filter_map { |id| records[id] }
        end
      rescue StandardError => e
        Rails.logger.error("[Ai::MessageDebouncer] Failed to drain messages for conversation ##{conversation.id}: #{e.message}")
        []
      end

      # Flushes buffer and clears timer (e.g. when human agent interrupts)
      def clear!(account_id, conversation_id)
        RedisUtilities::Helpers.delete(buffer_key(account_id, conversation_id))
        RedisUtilities::Helpers.delete(timer_key(account_id, conversation_id))
      rescue StandardError => e
        Rails.logger.warn("[Ai::MessageDebouncer] Failed to clear buffer for conversation ##{conversation_id}: #{e.message}")
      end
    end
  end
end
