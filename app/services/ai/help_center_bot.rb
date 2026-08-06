# frozen_string_literal: true

module Ai
  class HelpCenterBot < ApplicationService
    def initialize(account:, portal:, query:, user: nil, inbox: nil, conversation_history: [])
      @account = account
      @portal = portal
      @query = query
      @user = user
      @inbox = inbox
      @conversation_history = conversation_history
    end

    def call
      ai_agent = @inbox&.ai_agent

      # 1. Embed the customer query
      client = ::OpenAI::Client.new
      response = client.embeddings(
        parameters: {
          model: Ai::Client::MODELS[:embedding],
          input: @query
        }
      )
      query_embedding = response.dig("data", 0, "embedding")
      return no_match_response(ai_agent) unless query_embedding

      # 2. Search HelpCenter::Article using Searchkick dense_vector
      threshold = ai_agent&.confidence_threshold || 0.7
      search_results = HelpCenter::Article.search(
        body: {
          knn: {
            field: "translations.content_embedding",
            query_vector: query_embedding,
            k: 3,
            num_candidates: 10,
            filter: {
              bool: {
                must: [
                  { term: { "account_id.keyword" => @account.id } },
                  { term: { "portal_id.keyword" => @portal.id } },
                  { term: { "status.keyword" => "published" } },
                  { term: { "visibility.keyword" => "everyone" } }
                ]
              }
            }
          }
        }
      )

      # Filter out results that do not meet the AI agent's confidence threshold
      valid_hit_ids = search_results.response.dig("hits", "hits").to_a
                                    .select { |hit| hit["_score"].to_f >= threshold }
                                    .map { |hit| hit["_id"] }

      articles = search_results.select { |article| valid_hit_ids.include?(article.id.to_s) }

      return no_match_response(ai_agent) if articles.empty?

      # 3. Construct the RAG context
      context = articles.map do |article|
        t = article.translations.find { |trans| trans.locale == I18n.locale.to_s } || article.translations.first
        title = t&.title
        content = ActionView::Base.full_sanitizer.sanitize(t&.content.to_s)
        domain = article.portal&.domain&.value || "helpbolic.com"
        "Article: #{title}\nContent: #{content}\nURL: https://#{domain}/#{t&.locale}/articles/#{t&.slug}"
      end.join("\n\n---\n\n")

      # 4. Build system prompt — inject AiAgent config if available
      system_prompt = build_system_prompt(ai_agent, context)

      # 5. Generate the response using Ai::Client
      messages = @conversation_history + [{ role: "user", content: @query }]

      Ai::Client.call(
        account: @account,
        user: @user,
        action_type: "ai_agent_reply",
        model: :base,
        system_prompt: system_prompt,
        messages: messages
      )
    end

    private

    def build_system_prompt(ai_agent, context)
      base_instruction = ai_agent&.system_prompt.presence || 
        "You are a helpful customer support bot. Your job is to answer the customer's question using ONLY the provided Help Center Articles below.\n" \
        "If the answer is not contained in the articles, you must refuse to answer and politely offer to route the chat to a human agent.\n" \
        "Do not make up information or use outside knowledge."

      <<~PROMPT
        #{base_instruction}

        TONE: Respond in a #{ai_agent&.tone || 'professional'} manner.
        LANGUAGE: Reply in the same language as the user's message.

        RULES:
        - Answer ONLY using the Help Center Articles provided below.
        - If the answer is NOT in the articles, you MUST output this exact message:
          #{ai_agent&.fallback_message.presence || default_fallback}
        - Include the URL of the article you used at the end of your response, formatted as a markdown link (e.g. [Read Article](URL)).

        Help Center Articles:
        #{context.presence || 'No relevant articles found.'}
      PROMPT
    end

    def no_match_response(ai_agent)
      ai_agent&.fallback_message.presence || default_fallback
    end

    def default_fallback
      I18n.t("ai.widget_bot.default_fallback", default: "I don't have information about that. Let me connect you with a human agent.")
    end
  end
end
