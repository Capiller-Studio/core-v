# frozen_string_literal: true

module Ai
  class Summarizer < ApplicationService
    def initialize(conversation:, user:)
      @conversation = conversation
      @user = user
      @account = conversation.account
    end

    def call
      messages_text = format_messages
      
      return "Not enough messages to summarize." if messages_text.blank?

      system_prompt = <<~PROMPT
        You are an expert customer support assistant. Your job is to summarize the following conversation thread between a customer and the support team.
        Keep the summary concise (3-4 sentences max). Highlight the main issue, any troubleshooting steps taken, and the current status.
      PROMPT

      Ai::Client.call(
        account: @account,
        user: @user,
        action_type: "conversation_summary",
        model: :lite,
        system_prompt: system_prompt,
        messages: [
          { role: "user", content: messages_text }
        ]
      )
    end

    private

    def format_messages
      # Fetch the last 50 messages to keep within token limits and focus on recent context
      messages = @conversation.messages.order(created_at: :asc).last(50)
      
      messages.map do |msg|
        sender_type = msg.sender_type == "Customer" ? "Customer" : "Agent"
        "#{sender_type}: #{ActionView::Base.full_sanitizer.sanitize(msg.content)}"
      end.join("\n")
    end
  end
end
