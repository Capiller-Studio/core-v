# frozen_string_literal: true

module Ai
  class AgentWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: "default", dead: false

    sidekiq_retries_exhausted do |msg, _e|
      account_id, conversation_id, _message_id, _ai_agent_id = msg["args"]
      
      account = Account.find(account_id)
      account.with_shard do
        conversation = Conversation.find(conversation_id)
        
        # Unassign AI and force human auto-assignment
        conversation.update!(ai_status: :ai_handed_off)
        conversation.send(:auto_assign_agent) if conversation.send(:should_auto_assign?)
        
        # Add a private note explaining the AI crash
        ai_agent = Ai::Agent.find_by(id: _ai_agent_id)
        sender = ai_agent || account

        conversation.messages.create!(
          account: account,
          inbox_id: conversation.inbox_id,
          content: I18n.t("ai.agent.crash_note", default: "AI Agent repeatedly failed to process the customer's request. The conversation has been handed off to the human queue."),
          content_type: :activity,
          visibility: :personal,
          sender: sender
        )
      end
    end

    def perform(account_id, conversation_id, message_id, ai_agent_id)
      account = Account.find(account_id)

      account.with_shard do
        conversation = Conversation.find(conversation_id)
        message = Message.find(message_id)
        ai_agent = Ai::Agent.find(ai_agent_id)
        inbox = conversation.inbox

        # Temporarily set the locale so the fallback messages are correctly localized
        I18n.with_locale(conversation.locale || inbox.default_locale) do
          fallback = ai_agent.fallback_message.presence || 
                     I18n.t("ai.widget_bot.default_fallback", default: "I don't have information about that. Let me connect you with a human agent.")

          begin
            # Build multi-turn conversation history for context
            history = conversation.messages.order(:created_at).last(ai_agent.max_exchanges * 2).map do |msg|
              role = msg.sender_type == "Customer" ? "user" : "assistant"
              { role: role, content: ActionView::Base.full_sanitizer.sanitize(msg.content.to_s) }
            end

            # Get the portal for RAG search (prioritize agent-specific portal, fallback to channel portal)
            portal = ai_agent.portal || inbox.channel&.try(:portal)

            response = if portal
                         Ai::HelpCenterBot.call(
                           account: account,
                           portal: portal,
                           inbox: inbox,
                           query: message.content,
                           user: nil,
                           conversation_history: history
                         )
            else
                         fallback
            end

            # Check if this is an intentional handoff (the bot couldn't find an answer or the user asked for a human)
            is_handoff = (response == fallback)

            # Create AI response message in the conversation
            formatted_response = is_handoff ? response : Channels::MessageFormatter.parse_ai_markdown_to_html(response)
            
            ai_message = conversation.messages.create!(
              account: account,
              inbox_id: conversation.inbox_id,
              content: formatted_response,
              sender: ai_agent,
            )
            
            # Queue for delivery to the outbound channel (Email, WhatsApp, etc.)
            Messages::DeliveryWorker.perform_async(ai_message.account_id, ai_message.id)

            if is_handoff
              trigger_human_handoff(conversation, sender: ai_agent)
            end

          rescue StandardError => e
            if e.class.name == 'AiInsufficientBalanceError'
              Rails.logger.warn("[AI AgentWorker] Credits exhausted for account #{account_id}: #{e.message}")
              
              ai_message = conversation.messages.create!(
                account: account,
                inbox_id: conversation.inbox_id,
                content: fallback,
                sender: ai_agent,
              )
              Messages::DeliveryWorker.perform_async(ai_message.account_id, ai_message.id)

              trigger_human_handoff(conversation, sender: ai_agent, reason: I18n.t("ai.widget_bot.insufficient_credits_note", default: "AI Bot automatically halted due to insufficient AI Credits. Awaiting human agent."))
            elsif e.is_a?(OpenAI::Error) || e.is_a?(Faraday::Error)
              Rails.logger.error("[AI AgentWorker] API Error: #{e.message}")
              
              ai_message = conversation.messages.create!(
                account: account,
                inbox_id: conversation.inbox_id,
                content: fallback,
                sender: ai_agent,
              )
              Messages::DeliveryWorker.perform_async(ai_message.account_id, ai_message.id)

              trigger_human_handoff(conversation, sender: ai_agent, reason: I18n.t("ai.agent.api_error_note", default: "AI Bot encountered a temporary API error. Awaiting human agent."))
            else
              raise(e)
            end
          end
        end
      end
    end
    
    private
    
    def trigger_human_handoff(conversation, sender: nil, reason: nil)
      conversation.update!(ai_status: :ai_handed_off)
      
      if reason.present?
        sender ||= conversation.account
        conversation.messages.create!(
          account: conversation.account,
          inbox_id: conversation.inbox_id,
          content: reason,
          content_type: :activity,
          visibility: :personal,
          sender: sender
        )
      end
      
      conversation.send(:auto_assign_agent) if conversation.send(:should_auto_assign?)
    end
  end
end
