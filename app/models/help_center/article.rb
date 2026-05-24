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
    include Trackable
    include Publishable

    publishable_fields :title, :content

    belongs_to :account
    belongs_to :portal
    belongs_to :author, class_name: "User", optional: true
    belongs_to :primary_category, class_name: "HelpCenter::Category", optional: true

    has_many :category_resources, as: :resource, class_name: "HelpCenter::CategoryResource", dependent: :destroy
    has_many :categories, through: :category_resources

    has_many :related_resources, as: :resource, class_name: "HelpCenter::RelatedResource", dependent: :destroy
    has_many :related_articles, through: :related_resources, source: :linked_resource, source_type: "HelpCenter::Article"

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

    translates :title, :slug, :content, :meta_title, :meta_description, :draft_title, :draft_content

    # before_validation :set_default_primary_category

    searchkick word_start: ["translations.title", "translations.content"]

    def search_data
      {
        id: id,
        account_id: account_id,
        portal_id: portal_id,
        status: status,
        visibility: visibility,
        views_count: views_count,
        translations: translations.map do |t|
          {
            locale: t.locale,
            title: t.title,
            slug: t.slug,
            content: t.content,
            search_excerpt: t.search_excerpt
          }
        end
      }
    end

    attr_accessor :save_revision

    def to_param
      slug || id
    end

    private

    # Competitor-aligned formal Revision Checkpoint tracking
    # Ignores minor continuous typing auto-saves on published articles to preserve pristine milestone logs
    def should_track_changes?
      super && (saved_change_to_status? || save_revision)
    end

    # def set_default_primary_category
    #   self.primary_category_id ||= categories.first&.id
    # end
  end
end
