# frozen_string_literal: true

module Search
  class SearchService < ApplicationService
    CONVERSATION_FIELDS = %w[identifier^10 title^5 customer_name^3 customer_email^3 customer_phone^2 label_titles last_message_preview].freeze
    MESSAGE_FIELDS = %w[content sender_name].freeze

    def initialize(query:, account_id:, filters: {}, page: 1, per_page: 20, type: nil)
      @query = query.to_s.strip
      @account_id = account_id
      @filters = filters.symbolize_keys
      @page = [page.to_i, 1].max
      @per_page = [per_page.to_i, 50].min
      @type = type # nil = both, "conversations", "messages"
    end

    def call
      return empty_results if @query.blank?

      {
        conversations: search_conversations,
        messages: search_messages
      }
    end

    # Quick suggestions for typeahead (limited results, no pagination)
    def suggestions
      return { conversations: [], messages: [] } if @query.blank?

      {
        conversations: search_conversations(limit: 5),
        messages: search_messages(limit: 5)
      }
    end

    private

    def search_conversations(limit: nil)
      return [] if @type == "messages"

      where_clause = { account_id: @account_id }
      where_clause[:inbox_id] = @filters[:inbox_id] if @filters[:inbox_id].present?
      where_clause[:status] = @filters[:status] if @filters[:status].present?
      where_clause[:priority] = @filters[:priority] if @filters[:priority].present?
      where_clause[:assignee_id] = @filters[:assignee_id] if @filters[:assignee_id].present?
      where_clause[:team_id] = @filters[:team_id] if @filters[:team_id].present?

      if @filters[:date_from].present? || @filters[:date_to].present?
        date_range = {}
        date_range[:gte] = @filters[:date_from] if @filters[:date_from].present?
        date_range[:lte] = @filters[:date_to] if @filters[:date_to].present?
        where_clause[:created_at] = date_range
      end

      search_opts = {
        where: where_clause,
        fields: CONVERSATION_FIELDS,
        match: :word_start,
        order: { _score: :desc, last_activity_at: :desc },
        includes: [:customers, :inbox, :labels, :last_message, :assignee, :team]
      }

      if limit
        search_opts[:limit] = limit
      else
        search_opts[:page] = @page
        search_opts[:per_page] = @per_page
      end

      Conversation.search(@query, **search_opts)
    rescue StandardError, Searchkick::Error, Searchkick::MissingIndexError => e
      Rails.logger.error("[Search] Conversation search failed: #{e.message}")
      []
    end

    def search_messages(limit: nil)
      return [] if @type == "conversations"

      where_clause = {
        account_id: @account_id,
        content_type: "text",
        visibility: "global"
      }
      where_clause[:inbox_id] = @filters[:inbox_id] if @filters[:inbox_id].present?

      if @filters[:date_from].present? || @filters[:date_to].present?
        date_range = {}
        date_range[:gte] = @filters[:date_from] if @filters[:date_from].present?
        date_range[:lte] = @filters[:date_to] if @filters[:date_to].present?
        where_clause[:created_at] = date_range
      end

      search_opts = {
        where: where_clause,
        fields: MESSAGE_FIELDS,
        match: :word_start,
        highlight: { tag: "<mark>", fields: { content: {} } },
        order: { _score: :desc, created_at: :desc },
        includes: [:conversation, :sender]
      }

      if limit
        search_opts[:limit] = limit
      else
        search_opts[:page] = @page
        search_opts[:per_page] = @per_page
      end

      Message.search(@query, **search_opts)
    rescue StandardError, Searchkick::Error, Searchkick::MissingIndexError => e
      Rails.logger.error("[Search] Message search failed: #{e.message}")
      []
    end

    def empty_results
      { conversations: [], messages: [] }
    end
  end
end
