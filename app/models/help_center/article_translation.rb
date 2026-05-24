# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_article_translations
#
#  id              :uuid             not null, primary key
#  content         :text
#  locale          :string           not null
#  meta_description:text
#  meta_keywords   :string           default([]), not null, is an Array
#  meta_title      :text
#  search_excerpt  :text
#  slug            :string
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  article_id      :uuid             not null
#
# Indexes
#
#  index_help_center_article_translations_on_article_id             (article_id)
#  index_help_center_article_translations_on_article_id_and_locale  (article_id,locale) UNIQUE
#  index_help_center_article_translations_on_article_id_and_slug    (article_id,slug)
#  index_help_center_article_translations_on_locale                 (locale)
#  index_help_center_article_translations_on_title_and_locale       (title,locale)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => help_center_articles.id) ON DELETE => cascade
#
module HelpCenter
  class ArticleTranslation < ShardRecord
    belongs_to :article, class_name: "HelpCenter::Article"

    validates :locale, presence: true
    validates :title,  presence: true

    before_validation :generate_slug, on: :create

    private

    def generate_slug
      return if slug.present? || title.blank?
      
      base = title.parameterize
      candidate = base
      counter = 1
      
      while slug_exists?(candidate)
        counter += 1
        candidate = "#{base}-#{counter}"
      end
      
      self.slug = candidate
    end

    def slug_exists?(candidate)
      return false unless article

      self.class.joins(:article)
          .where(locale: locale, slug: candidate, help_center_articles: { portal_id: article.portal_id })
          .where.not(id: id)
          .exists?
    end

    # slug is locale-specific for proper multi-language SEO.
    # Stores only the path segment (e.g. "setup-whatsapp-channel").
    # The locale prefix (/en/, /es/) is prepended by the router, not stored here.
    # Uniqueness is enforced at the portal level via the router + controller.

    # search_excerpt is a pre-computed plain-text snippet (HTML/Markdown stripped)
    # used for displaying search result previews without re-parsing content at query time.
  end
end
