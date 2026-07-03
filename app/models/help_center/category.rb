# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_categories
#
#  id             :uuid             not null, primary key
#  ancestry       :string
#  ancestry_depth :integer          default(0), not null
#  children_count :integer          default(0), not null
#  code           :string           not null
#  configurations :jsonb            not null
#  featured       :boolean          default(FALSE), not null
#  flags          :integer          default(0), not null
#  icon_key       :string
#  identifier     :string           not null
#  permalink      :string           not null
#  position       :integer
#  status         :integer          default("active"), not null
#  visibility     :integer          default("public"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  portal_id      :uuid             not null
#
# Indexes
#
#  index_help_center_categories_on_account_id                (account_id)
#  index_help_center_categories_on_portal_id                 (portal_id)
#  index_help_center_categories_on_portal_id_and_ancestry    (portal_id,ancestry)
#  index_help_center_categories_on_portal_id_and_created_at  (portal_id,created_at)
#  index_help_center_categories_on_portal_id_and_featured    (portal_id,featured)
#  index_help_center_categories_on_portal_id_and_flags       (portal_id,flags)
#  index_help_center_categories_on_portal_id_and_identifier  (portal_id,identifier) UNIQUE
#  index_help_center_categories_on_portal_id_and_permalink   (portal_id,permalink) UNIQUE
#  index_help_center_categories_on_portal_id_and_position    (portal_id,position)
#  index_help_center_categories_on_portal_id_and_status      (portal_id,status)
#  index_help_center_categories_on_portal_id_and_visibility  (portal_id,visibility)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => help_center_portals.id) ON DELETE => cascade
#
module HelpCenter
  class Category < ShardRecord
    include Translateable
    include FlagShihTzu

    has_ancestry cache_depth: true, counter_cache: true, primary_key_format: /[0-9a-f\-]+/i

    belongs_to :account
    belongs_to :portal

    has_many :category_resources, class_name: "HelpCenter::CategoryResource", dependent: :destroy
    has_many :articles, through: :category_resources, source: :resource, source_type: "HelpCenter::Article"

    has_one_attached :image # Custom JPG/PNG/WebP image; takes precedence over icon_key when present

    enum :status, { active: 0 }

    # visibility controls who can see this category:
    #   everyone  — visible to all visitors
    #   unlisted  — accessible via direct link, not shown in navigation
    #   internal  — visible to authenticated agents/team only
    enum :visibility, { everyone: 0, unlisted: 1, internal: 2 }

    # flags (FlagShihTzu bit fields):
    #   guide_mode — when enabled, articles in this category are treated as sequential steps.
    #                Readers see a step progress indicator ("Step 2 of 5") and Next/Previous buttons.
    #                Agents see step numbers in the article list and position ordering is enforced.
    #                Use this for multi-step setup guides (e.g. WhatsApp channel configuration).
    has_flags 1 => :guide_mode,
              2 => :show_in_navbar,
              3 => :featured,
              4 => :api_reference,
              column: "flags"

    # icon_key stores a key from the predefined Lucide icon set (e.g. "book-open", "message-circle")
    # The actual SVG is rendered per-app (deskbolic/helpbolic independently bundle Lucide)
    # Custom :image attachment takes precedence over icon_key when both are present

    translates :name, :description, :slug

    searchkick word_start: ["translations.name", "translations.description"]

    def search_data
      {
        id: id,
        account_id: account_id,
        portal_id: portal_id,
        status: status,
        visibility: visibility,
        translations: translations.map do |t|
          {
            locale: t.locale,
            name: t.name,
            slug: t.slug,
            description: t.description
          }
        end
      }
    end

    def to_param
      slug || id
    end
  end
end
