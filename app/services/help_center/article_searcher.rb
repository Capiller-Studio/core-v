# frozen_string_literal: true

module HelpCenter
  class ArticleSearcher < ApplicationService
    attr_reader :query, :account, :portal, :locale

    def initialize(query:, account:, portal:, locale: I18n.locale)
      @query = query
      @account = account
      @portal = portal
      @locale = locale.to_s
    end

    def call
      return [] if query.blank?
      return [] if portal.blank?

      Article.search(
        query,
        where: {
          account_id: account.id,
          portal_id: portal.id,
          status: "published"
        },
        fields: [ "translations.title^3", "translations.content" ],
        match: :word_start,
        boost_by: { views_count: { factor: 1.2 } }
      )
    end
  end
end
