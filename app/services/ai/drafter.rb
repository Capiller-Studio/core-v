# frozen_string_literal: true

module Ai
  class Drafter < ApplicationService
    def initialize(conversation:, user:, instruction:)
      @conversation = conversation
      @user = user
      @instruction = instruction
      @account = conversation.account
    end

    def call
      messages_text = format_messages
      rag_context = fetch_rag_context

      system_prompt = <<~PROMPT
        You are an expert customer support agent drafting a reply to a customer.
        Use the conversation history provided by the user to understand the context.
        Draft a polite, professional, and empathetic response based on the following instruction:
        "#{@instruction}"
        
        #{rag_context.present? ? "Use the following Help Center Articles as your primary source of factual information:\n#{rag_context}" : ""}
        
        LANGUAGE: Respond in the same language as the conversation history. If uncertain, default to locale: #{I18n.locale}.
        
        Output ONLY the drafted reply, without any quotation marks or extra conversational text.
      PROMPT

      Ai::Client.call(
        account: @account,
        user: @user,
        action_type: "draft_reply",
        model: rag_context.present? ? :base : :lite, # Use slightly more powerful model for RAG parsing
        system_prompt: system_prompt,
        messages: [
          { role: "user", content: "Conversation History:\n#{messages_text}" }
        ]
      )
    end

    private

    def fetch_rag_context
      ai_agent = @conversation.inbox&.ai_agent
      portal = ai_agent&.portal
      return nil unless portal

      last_customer_message = @conversation.messages.where(sender_type: ["Customer", "Contact"]).last
      return nil unless last_customer_message

      client = ::OpenAI::Client.new
      response = client.embeddings(
        parameters: {
          model: Ai::Client::MODELS[:embedding],
          input: ActionView::Base.full_sanitizer.sanitize(last_customer_message.content)
        }
      )
      query_embedding = response.dig("data", 0, "embedding")
      return nil unless query_embedding

      articles = HelpCenter::Article.search(
        body: {
          knn: {
            field: "translations.content_embedding",
            query_vector: query_embedding,
            k: 3,
            num_candidates: 10,
            filter: {
              bool: {
                must: [
                  { term: { account_id: @account.id } },
                  { term: { portal_id: portal.id } },
                  { term: { status: "published" } },
                  { term: { visibility: "everyone" } }
                ]
              }
            }
          }
        }
      )

      return nil if articles.empty?

      articles.map do |article|
        t = article.translations.find { |trans| trans.locale == I18n.locale.to_s } || article.translations.first
        title = t&.title
        content = ActionView::Base.full_sanitizer.sanitize(t&.content.to_s)
        "Article: #{title}\nContent: #{content}"
      end.join("\n\n")
    end

    def format_messages
      messages = @conversation.messages.order(created_at: :asc).last(20)
      
      return "No previous messages." if messages.empty?

      messages.map do |msg|
        sender_type = msg.sender_type == "Customer" ? "Customer" : "Agent"
        "#{sender_type}: #{ActionView::Base.full_sanitizer.sanitize(msg.content)}"
      end.join("\n")
    end
  end
end
