# frozen_string_literal: true

module Ai
  class ThankYouDetectorWorker
    include Sidekiq::Worker
    sidekiq_options retry: 3, queue: "default"

    def perform(message_id)
      message = Message.find_by(id: message_id)
      return unless message && message.incoming?
      
      conversation = message.conversation
      account = conversation.account
      
      # We only care if this message caused a reopened conversation.
      # When a message reopens a conversation, the conversation's status_changed_at
      # is updated synchronously just before the message is created.
      # (We use this instead of the Activity table because activities are logged asynchronously).
      return unless conversation.status_changed_at.present?
      return unless (conversation.status_changed_at - message.created_at).abs <= 5.seconds
      
      content = message.content.to_s.strip
      
      # Fast-path regex to save OpenAI credits for obvious "Thank you" messages
      if is_obvious_thank_you?(content)
        revert_reopen(conversation, message)
        return
      end

      # Skip if message is too long (likely a real reply)
      return if content.length > 200

      system_prompt = <<~PROMPT
        You are a helpdesk assistant analyzing a customer's message.
        Determine if this message is merely a polite "Thank you", an acknowledgment, or an Out-of-Office (OOO) auto-reply.
        If it contains a new question, a follow-up issue, or requires an agent's response, it is NOT just a thank you.

        Output ONLY a JSON object with a single boolean key "is_thank_you_or_ooo": true or false.
      PROMPT

      response = Ai::Client.call(
        account: account,
        action_type: "thank_you_detection",
        model: :lite,
        system_prompt: system_prompt,
        messages: [{ role: "user", content: content }],
        response_format: "json_object"
      )

      begin
        parsed = JSON.parse(response)
        if parsed["is_thank_you_or_ooo"] == true
          revert_reopen(conversation, message)
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse ThankYou detection: #{e.message}")
      end
    rescue ::AiInsufficientBalanceError
      # Ignore
    end

    private

    def is_obvious_thank_you?(text)
      normalized = text.downcase.gsub(/[^a-z\s]/, '')
      # Match common short phrases
      %w[thank you thanks ty thanks a lot thank you so much awesome thanks great thanks ok thanks okay thanks].include?(normalized.strip)
    end

    def revert_reopen(conversation, message)
      if conversation.active?
        conversation.update!(status: :resolved)
        
        # Tag the message so agents know it was detected
        ai_metadata = message.ai_metadata || {}
        ai_metadata["auto_resolved"] = true
        message.update!(ai_metadata: ai_metadata)
      end
    end
  end
end
