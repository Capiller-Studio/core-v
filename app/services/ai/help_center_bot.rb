# frozen_string_literal: true

module Ai
  class HelpCenterBot < ApplicationService
    class Response
      attr_reader :content, :intent

      delegate :to_s, to: :content

      def initialize(content:, handoff:, intent:)
        @content = content
        @handoff = handoff
        @intent = intent
      end

      def handoff?
        @handoff == true
      end

      def ==(other)
        if other.is_a?(String)
          @content == other
        elsif other.is_a?(Response)
          @content == other.content && @handoff == other.handoff? && @intent == other.intent
        else
          super
        end
      end
    end

    # Tier 1: Fast Universal Escalation Dictionary (< 1ms, 0 OpenAI cost)
    # Explicit human handoff patterns across all 7 platform languages:
    # English (en), Arabic (ar), German (de), Spanish (es), French (fr), Korean (ko), Portuguese (pt/pt-BR).
    ESCALATION_PATTERNS = [
      # English
      /\b(?:talk|speak)\s+to\s+(?:a\s+)?(?:human|agent|person|representative|support|someone)\b/i,
      /\b(?:connect|transfer)\s+(?:me\s+)?to\s+(?:a\s+)?(?:human|agent|person|representative)\b/i,
      /\breal\s+(?:person|human|agent)\b/i,
      /\b(?:human|agent|representative)\s+please\b/i,
      /\bhuman\s+support\b/i,
      /\bcustomer\s+service\s+(?:agent|representative|person)\b/i,
      /\bpass\s+(?:me\s+)?to\s+(?:a\s+)?human\b/i,

      # Spanish
      /(?:hablar|comunicar(?:me)?|conectar(?:me)?|pasar(?:me)?)\s+con\s+(?:un\s+)?(?:humano|agente|operador|representante|persona)/i,
      /\b(?:persona|humano)\s+real\b/i,
      /\batenci[oó]n\s+al\s+cliente\b/i,
      /\bagente\s+humano\b/i,
      /\b(?:humano|agente|operador)\s+por\s+favor\b/i,

      # French
      /(?:parler|discuter|communiquer|transf[eé]rer|passer)\s+[aà]\s+(?:un\s+)?(?:humain|conseiller|agent|op[eé]rateur|repr[eé]sentant|personne)/i,
      /\bpersonne\s+r[eé]elle\b/i,
      /\bservice\s+client(?:[eè]le)?\b/i,
      /\bagent\s+humain\b/i,
      /\b(?:humain|conseiller)\s+s[' ]il\s+vous\s+pla[iî]t\b/i,

      # German
      /(?:mit\s+(?:einem\s+)?(?:menschen|mitarbeiter|berater|kundendienst|echte(?:n|r)?\s+person)\s+sprechen)/i,
      /(?:verbinde|weiterleiten|sprechen\s+mit)\s+(?:mich\s+)?(?:mit\s+)?(?:einem\s+)?(?:menschen|mitarbeiter|berater)/i,
      /\bechte\s+person\b/i,
      /\bmenschlicher\s+(?:support|mitarbeiter|berater)\b/i,
      /\bbitte\s+(?:einen\s+)?(?:menschen|mitarbeiter)\b/i,

      # Arabic
      /(?:تحدث|التحدث|تكلم|التكلم|اتكلم|اريد\s+التحدث|تحويل(?:ي)?|توصيل(?:ي)?)\s+(?:مع|إلى|الى)\s+(?:موظف|شخص|بشري|إنسان|ممثل|خدمة\s+العملاء)/u,
      /(?:شخص|موظف|إنسان|انسان)\s+حقيقي/u,
      /(?:موظف|خدمة\s+العملاء)\s+(?:لو\s+سمحت|من\s+فضلك|رجاء)/u,
      /خدمة\s+العملاء/u,

      # Korean
      /(?:상담원|상담사|사람|직원|실제\s*사람)(?:과|이랑)?\s*(?:연결|대화|통화|바꿔|부탁)/u,
      /(?:상담원|상담사|직원)\s*(?:연결해\s*줘|부탁드립니다|연결)/u,

      # Portuguese
      /(?:falar|conversar|transferir|conectar|passar)\s+(?:com\s+)?(?:um\s+)?(?:humano|atendente|agente|operador|representante|pessoa)/i,
      /\bpessoa\s+real\b/i,
      /\batendimento\s+humano\b/i,
      /\bagente\s+humano\b/i,
      /\b(?:humano|atendente)\s+por\s+favor\b/i
    ].freeze

    GREETING_WORDS = %w[
      hi hello hey heya hiya howdy greetings
      hola buenos buenas
      bonjour salut coucou
      hallo guten moin
      مرحبا أهلا اهلا سلام
      안녕 안녕하세요
      olá ola oi
    ].freeze

    NAME_PATTERNS = [
      /(?:my name is|i am|i'm)\s+([A-Za-z]+)/i,
      /(?:me llamo|mi nombre es|soy)\s+([A-Za-z]+)/i,
      /(?:je m'appelle|mon nom est|je suis)\s+([A-Za-z]+)/i,
      /(?:ich hei[ßs]e|mein name ist|ich bin)\s+([A-Za-z]+)/i,
      /(?:meu nome [eé]|me chamo|sou (?:o|a)?)\s+([A-Za-z]+)/i,
      /(?:اسمي|أنا|انا)\s+([^\s\d!?,.]+)/u
    ].freeze

    def initialize(account:, portal:, query:, user: nil, inbox: nil, conversation_history: [])
      @account = account
      @portal = portal
      @query = query
      @user = user
      @inbox = inbox
      @conversation_history = conversation_history
    end

    def call
      @account.with_shard do
        ai_agent = @inbox&.ai_agent
        clean_query = @query.to_s.strip

        # 1. Media or Empty query check
        if clean_query.blank?
          media_msg = I18n.t("ai.agent.media_handoff", default: "Thanks for sharing that! Let me connect you with a team member who can review your attachment.")
          return Response.new(content: media_msg, handoff: true, intent: :media_attachment)
        end

        # 2. Tier 1: Explicit request for human support (0-cost fast dictionary)
        if explicit_human_request?(clean_query)
          return Response.new(content: handoff_message(ai_agent), handoff: true, intent: :human_requested)
        end

        # 3. Knowledge Base RAG
        unless @portal
          return Response.new(content: no_match_response(ai_agent), handoff: true, intent: :no_portal)
        end

        # 3a. Embed the customer query
        client = ::OpenAI::Client.new
        response = client.embeddings(
          parameters: {
            model: Ai::Client::MODELS[:embedding],
            input: clean_query
          }
        )
        query_embedding = response.dig("data", 0, "embedding")
        return Response.new(content: no_match_response(ai_agent), handoff: true, intent: :embedding_error) unless query_embedding

        # 3b. Search HelpCenter::Article using Searchkick dense_vector
        threshold = ai_agent&.confidence_threshold || 0.7
        search_results = HelpCenter::Article.search(
          body: {
            knn: {
              field: "embeddings.content_embedding",
              query_vector: query_embedding,
              k: 3,
              num_candidates: 10,
              filter: {
                bool: {
                  must: [
                    { term: { account_id: @account.id } },
                    { term: { portal_id: @portal.id } },
                    { term: { status: "published" } },
                    { term: { visibility: "everyone" } }
                  ]
                }
              }
            }
          }
        )

        raw_hits =
          if search_results.response["hits"].is_a?(Hash)
            search_results.response.dig("hits", "hits")
          else
            search_results.response["hits"]
          end
        valid_hit_ids = raw_hits.to_a
                                .select { |hit| hit["_score"].to_f >= threshold }
                                .pluck("_id")

        articles = search_results.select { |article| valid_hit_ids.include?(article.id.to_s) }

        # Short-circuit: If 1-2 words vague inquiry (not greeting) and no articles matched, ask for clarification
        if articles.empty?
          words = clean_query.split(/\s+/)
          if words.length <= 2 && clean_query.exclude?("?") && !greeting_query?(clean_query)
            clarification = I18n.t("ai.agent.clarification_request",
                                   query: clean_query,
                                   default: "Could you please provide a bit more detail about your request regarding '%{query}'?")
            return Response.new(content: clarification, handoff: false, intent: :clarification)
          end
        end

        # 3c. Construct RAG context
        context = articles.map do |article|
          t = article.translations.find { |trans| trans.locale == I18n.locale.to_s } || article.translations.first
          title = t&.title
          content = ActionView::Base.full_sanitizer.sanitize(t&.content.to_s)
          domain = article.portal&.domain&.value || "helpbolic.com"
          "Article: #{title}\nContent: #{content}\nURL: https://#{domain}/#{t&.locale}/articles/#{t&.slug}"
        end.join("\n\n---\n\n")

        # 3d. Build unified multilingual cognitive prompt
        customer_name = extract_name_from_greeting(clean_query) || @user&.name
        system_prompt = build_system_prompt(ai_agent, context, customer_name)

        # 3e. Generate LLM response
        messages = @conversation_history + [{ role: "user", content: clean_query }]

        begin
          ai_response = Ai::Client.call(
            account: @account,
            user: @user,
            action_type: "ai_agent_reply",
            model: :base,
            system_prompt: system_prompt,
            messages: messages
          )
        rescue StandardError => e
          raise if e.class.name == "AiInsufficientBalanceError"

          if greeting_fallback_applicable?(clean_query)
            fallback_greeting =
              if customer_name.present?
                I18n.t("ai.agent.personalized_greeting", name: customer_name, default: "Hello %{name}! How can I help you today?")
              else
                ai_agent&.greeting_message.presence || I18n.t("ai.agent.default_greeting", default: "Hello! How can I help you today?")
              end
            return Response.new(content: fallback_greeting, handoff: false, intent: :greeting)
          end

          raise(e)
        end

        # 3f. Deterministic evaluation of control tokens
        parse_ai_response(ai_response, ai_agent, articles, clean_query)
      end
    end

    private

    def explicit_human_request?(text)
      normalized = text.to_s.strip
      return false if normalized.blank?

      ESCALATION_PATTERNS.any? { |pattern| normalized.match?(pattern) }
    end

    def greeting_query?(text)
      normalized = text.to_s.downcase.gsub(/[^a-z0-9\p{Arabic}\p{Hangul}\s]/u, " ").squish
      return false if normalized.blank?
      return false if text.include?("?")

      words = normalized.split
      words.length <= 8 && (
        words.any? { |w| GREETING_WORDS.include?(w) } ||
        extract_name_from_greeting(text).present?
      )
    end

    def greeting_fallback_applicable?(text)
      lines = text.to_s.split(/[\n\r]+/).map(&:strip).compact_blank
      return true if lines.any? { |l| greeting_query?(l) }

      greeting_query?(text)
    end

    def extract_name_from_greeting(text)
      NAME_PATTERNS.each do |pattern|
        match = text.match(pattern)
        return match[1].strip.capitalize if match && match[1].present?
      end
      nil
    end

    def build_system_prompt(ai_agent, context, customer_name)
      base_instruction = ai_agent&.system_prompt.presence || "You are a helpful customer support assistant."
      tone = ai_agent&.tone || "friendly"
      name_hint = customer_name.present? ? "The customer's name is #{customer_name}." : nil

      <<~PROMPT
        #{base_instruction}

        TONE: Respond in a #{tone} manner.
        LANGUAGE: Always reply in the same language as the customer's message (e.g. Arabic, German, Spanish, French, Korean, Portuguese, English).
        #{name_hint}

        EVALUATION RULES:
        1. INTENT: SMALL TALK / GREETING ONLY:
           If the customer's message is only a greeting (e.g. "Hi", "Hello", "Hola", "مرحبا", "Bonjour", "Guten Tag"), stating their name, or asking pleasantries without asking a specific technical or support question:
           - Greet them warmly in their language.
           - If they shared their name, address them politely by name.
           - Ask how you can assist them today.
           - DO NOT mention articles or offer human handoff.

        2. INTENT: EXPLICIT HUMAN REQUEST:
           If the customer is asking to speak with a human agent or expressing refusal to talk to a bot in any language:
           - Output exact token: [HUMAN_HANDOFF_REQUESTED]

        3. INTENT: KNOWLEDGE QUESTION:
           - If answerable using the Help Center Articles below:
             Answer accurately based ONLY on the articles. Include the article URL at the end as a markdown link (e.g. [Read Article](URL)).
           - If the question is ambiguous or only 1-2 words: Ask a polite clarifying question.
           - If unanswerable from the articles:
             Output exact token: [NO_DOCUMENTATION_FOUND]

        Help Center Articles:
        #{context.presence || 'No relevant articles found.'}
      PROMPT
    end

    def parse_ai_response(ai_response, ai_agent, articles, clean_query)
      response_str = ai_response.to_s.strip

      if response_str.include?("[HUMAN_HANDOFF_REQUESTED]")
        Response.new(content: handoff_message(ai_agent), handoff: true, intent: :human_requested)
      elsif response_str.include?("[NO_DOCUMENTATION_FOUND]")
        Response.new(content: no_match_response(ai_agent), handoff: true, intent: :fallback_handoff)
      else
        intent =
          if articles.present?
            :rag_answer
          elsif greeting_fallback_applicable?(clean_query)
            :greeting
          elsif clean_query.split(/\s+/).length <= 2 && clean_query.exclude?("?")
            :clarification
          else
            :conversational_answer
          end
        Response.new(content: response_str, handoff: false, intent: intent)
      end
    end

    def handoff_message(ai_agent)
      ai_agent&.handoff_message.presence ||
        ai_agent&.fallback_message.presence ||
        I18n.t("ai.agent.connecting_to_human", default: "I'm connecting you with a human agent now. Someone from our team will be with you shortly.")
    end

    def no_match_response(ai_agent)
      ai_agent&.fallback_message.presence || default_fallback
    end

    def default_fallback
      I18n.t("ai.widget_bot.default_fallback", default: "Sorry, I am unable to answer this question. Connecting you to a human agent...")
    end
  end
end
