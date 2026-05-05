# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_articles
#
#  id             :uuid             not null, primary key
#  article_type   :integer          default("standard"), not null
#  configurations :jsonb            not null
#  flags          :integer          default(0), not null
#  position       :integer
#  status         :integer          default("draft"), not null
#  views_count    :integer          default(0), not null
#  visibility     :integer          default("public"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  author_id      :uuid
#  portal_id      :uuid             not null
#
# Indexes
#
#  index_help_center_articles_on_account_id                  (account_id)
#  index_help_center_articles_on_author_id                   (author_id)
#  index_help_center_articles_on_portal_id                   (portal_id)
#  index_help_center_articles_on_portal_id_and_article_type  (portal_id,article_type)
#  index_help_center_articles_on_portal_id_and_created_at    (portal_id,created_at)
#  index_help_center_articles_on_portal_id_and_flags         (portal_id,flags)
#  index_help_center_articles_on_portal_id_and_position      (portal_id,position)
#  index_help_center_articles_on_portal_id_and_status        (portal_id,status)
#  index_help_center_articles_on_portal_id_and_visibility    (portal_id,visibility)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
module HelpCenter
  class Article < ShardRecord
    include Translateable

    belongs_to :account
    belongs_to :portal
    belongs_to :author, class_name: "User", optional: true

    has_many_attached :images       # Inline images embedded within article content
    has_one_attached  :banner_image # Hero/banner displayed at the top of the article page

    enum :status, { draft: 0, published: 1, archived: 2 }

    # article_type controls dashboard editor behaviour and frontend rendering:
    #   standard       — full rich text editor shown; renders as a standard documentation page
    #   external_link  — URL input shown instead of editor; acts as a navigation link in the sidebar;
    #                    target URL stored in configurations["external_url"]
    # NOTE: Guide/wizard sequencing is NOT an article type — it is a Category-level flag (guide_mode).
    #       Articles inside a guide_mode category automatically get Next/Previous step navigation.
    enum :article_type, { standard: 0, external_link: 1 }

    # visibility controls who can access this article:
    #   everyone  — visible to all visitors
    #   unlisted  — accessible via direct link only, not shown in navigation/search
    #   internal  — visible to authenticated agents/team only
    enum :visibility, { everyone: 0, unlisted: 1, internal: 2 }

    # configurations jsonb structure:
    # {
    #   "external_url"             => "https://...",  (ONLY for external_link type — the redirect destination)
    #   "show_table_of_contents"   => true,           (render right-side ToC panel; ignored for external_link)
    #   "estimated_read_time"      => 5               (minutes; auto-computed from content length or manually overridden)
    # }

    translates :title, :content, :meta_title, :meta_description

    searchkick

    def search_data
      {
        id: id,
        account_id: account_id,
        portal_id: portal_id,
        status: status,
        views_count: views_count,
        translations: translations.map do |t|
          {
            locale: t.locale,
            title: t.title,
            content: t.content,
            search_excerpt: t.search_excerpt
          }
        end
      }
    end
  end
end
