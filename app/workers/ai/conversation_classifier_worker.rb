# frozen_string_literal: true

module Ai
  class ConversationClassifierWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: "default"

    # Only attempt classification once per conversation
    # We lock on the conversation ID to prevent duplicate requests from rapid sequential messages
    def perform(conversation_id)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation

      account = conversation.account
      return unless account.feature_enabled?(:ai_copilot) || account.feature_enabled?(:ai_agent)

      lock_key = ::RedisUtilities::Keys::AI_CLASSIFIER_LOCK % { account_id: account.id, conversation_id: conversation.id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key, timeout: 30.minutes) do
        account.with_shard do
          # Ensure we haven't already classified this conversation
          return if conversation.ai_metadata&.key?("sentiment") || conversation.ai_metadata&.key?("category")

          # Get the first message from the customer
          initial_message = conversation.messages.where(sender_type: "Customer").order(:created_at).first
          return unless initial_message && initial_message.content.present?

          # Fetch active labels for categorization
          active_labels = account.labels.pluck(:title)
          
          system_prompt = <<~PROMPT
            You are an advanced classification AI for a helpdesk.
            Analyze the following customer message and determine its Sentiment and Category.
            
            Sentiment must be one of: "positive", "neutral", "negative", "angry".
            Priority must be one of: "low", "normal", "high", "urgent" based on urgency keywords.
            Category must be one of the following labels: #{active_labels.any? ? active_labels.join(', ') : 'unknown'}

            If no category matches, use "unknown".
            Output your response as a JSON object with keys "sentiment", "priority", and "category".
          PROMPT

          response = Ai::Client.call(
            account: account,
            action_type: "conversation_classification",
            model: :lite,
            system_prompt: system_prompt,
            messages: [{ role: "user", content: initial_message.content }],
            response_format: "json_object"
          )

          begin
            parsed_data = JSON.parse(response)
            
            sentiment = parsed_data["sentiment"]
            priority = parsed_data["priority"]
            category = parsed_data["category"]

            new_ai_metadata = conversation.ai_metadata || {}
            new_ai_metadata["sentiment"] = sentiment if sentiment.present?
            new_ai_metadata["category"] = category if category.present? && category != "unknown"

            update_attrs = { ai_metadata: new_ai_metadata }
            
            # Map priority to Conversation.priorities enum if valid
            if priority.present? && Conversation.priorities.key?(priority)
              update_attrs[:priority] = priority
            end

            conversation.update!(update_attrs)

            # Apply the label if it exists and auto labelling is enabled
            if conversation.inbox.ai_auto_labelling? && category.present? && category != "unknown" && active_labels.include?(category)
              label = account.labels.find_by(title: category)
              if label
                conversation.applied_labels.find_or_create_by!(label: label)
              end
            end

          rescue JSON::ParserError => e
            Rails.logger.error("Failed to parse AI classification: #{e.message}")
          end
        end
      end
    rescue ::AiInsufficientBalanceError
      Rails.logger.info("Skipped AI classification for conversation #{conversation_id} due to insufficient credits.")
    rescue ::MutexLockError
      # Already running or locked, safe to ignore
    end
  end
end
