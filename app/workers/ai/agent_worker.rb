# frozen_string_literal: true

module Ai
  class AgentWorker
    include Sidekiq::Worker
    sidekiq_options retry: 2, queue: "default", dead: false

    sidekiq_retries_exhausted do |msg, _e|
      account_id = msg["args"][0]
      conversation_id = msg["args"][1]
      ai_agent_id = msg["args"][2]
      
      account = Account.find(account_id)
      account.with_shard do
        conversation = Conversation.find(conversation_id)
        
        # Unassign AI and force human auto-assignment
        conversation.update!(ai_status: :ai_handed_off)
        conversation.send(:auto_assign_agent) if conversation.send(:should_auto_assign?)
        
        # Add a private note explaining the AI crash
        ai_agent = Ai::Agent.find_by(id: ai_agent_id)
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

    def perform(account_id, conversation_id, ai_agent_id, token = nil)
      account = Account.find(account_id)

      account.with_shard do
        conversation = Conversation.find_by(id: conversation_id)
        return unless conversation&.ai_active?

        ai_agent = Ai::Agent.find_by(id: ai_agent_id)
        return unless ai_agent&.active_and_configured?

        # 1. Debounce check: if a newer message arrived in the sliding window, this job is superseded
        if token.present? && !Ai::MessageDebouncer.ready_to_process?(account_id, conversation_id, token)
          return
        end

        # 2. Drain all buffered customer messages for this conversation
        messages = Ai::MessageDebouncer.drain_messages(account, conversation)
        return if messages.blank?

        inbox = conversation.inbox

        # 3. Broadcast typing indicator: START
        broadcast_typing_status(conversation, "start")

        # Temporarily set the locale so the fallback messages are correctly localized
        I18n.with_locale(conversation.locale || inbox.default_locale) do
          fallback = ai_agent.fallback_message.presence || 
                     I18n.t("ai.widget_bot.default_fallback", default: "Sorry, I am unable to answer this question. Connecting you to a human agent...")

          begin
            # Combine debounced user messages into a unified query
            sanitized_fragments = messages.map { |m| ActionView::Base.full_sanitizer.sanitize(m.content.to_s).strip }
            bundled_query = sanitized_fragments.compact_blank.join("\n")

            # Build conversation history excluding the messages just bundled
            buffered_ids = messages.map(&:id)
            recent_messages = conversation.messages.where.not(id: buffered_ids).order(:created_at).last(ai_agent.max_exchanges * 2)
            history = recent_messages.map do |msg|
              role = msg.sender_type == "Customer" ? "user" : "assistant"
              { role: role, content: ActionView::Base.full_sanitizer.sanitize(msg.content.to_s) }
            end

            # Get the portal for RAG search (prioritize agent-specific portal, fallback to channel portal)
            portal = ai_agent.portal || inbox.channel&.try(:portal)

            bot_result = if portal
                           Ai::HelpCenterBot.call(
                             account: account,
                             portal: portal,
                             inbox: inbox,
                             query: bundled_query,
                             user: nil,
                             conversation_history: history
                           )
            else
                           fallback
            end

            is_handoff = bot_result.respond_to?(:handoff?) ? bot_result.handoff? : (bot_result.to_s == fallback)
            raw_response = bot_result.respond_to?(:content) ? bot_result.content : bot_result.to_s

            # Turn off typing indicator before publishing message
            broadcast_typing_status(conversation, "stop")

            # Format markdown to HTML unless intentional handoff
            formatted_response = is_handoff ? raw_response : Channels::MessageFormatter.parse_ai_markdown_to_html(raw_response)
            
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
            broadcast_typing_status(conversation, "stop")

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

    def broadcast_typing_status(conversation, status)
      tokens = conversation.customer_inboxes.pluck(:connection_token) + conversation.users.pluck(:connection_token)

      payload = {
        event: "typing",
        conversation_id: conversation.id,
        sender_type: "Ai::Agent",
        status: status
      }

      tokens.compact!
      tokens.uniq!

      tokens.each do |token|
        ActionCable.server.broadcast(token, payload)
      end
    rescue StandardError => e
      Rails.logger.warn("[AI AgentWorker] Typing broadcast warning: #{e.message}")
    end
    
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
