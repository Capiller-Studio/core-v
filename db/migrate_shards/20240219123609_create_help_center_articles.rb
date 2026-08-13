class CreateHelpCenterArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_articles, id: :uuid do |t|
      t.integer :views_count, null: false, default: 0
      t.jsonb   :configurations, null: false, default: {}
      t.jsonb   :stats, null: false, default: {}
      t.integer :position

      # article_type: standard (0) — regular documentation/help article with full content editor
      #              external_link (1) — navigation link only; URL stored in configurations["external_url"],
      #                                  no content editor shown; acts as a redirect in the sidebar nav
      # Guide sequencing (step-by-step flow) is handled at the Category level via guide_mode flag,
      # NOT at the article level. Articles within a guide_mode category are ordered steps.
      t.integer :article_type, null: false, default: 0

      # visibility: everyone (0) — visible to all, unlisted (1) — accessible via link only, internal (2) — agents only
      t.integer :visibility, null: false, default: 0

      # status: draft (0) — work in progress, published (1) — live, archived (2) — no longer shown
      t.integer :status, null: false, default: 0
      t.integer :flags,  null: false, default: 0

      t.references :account, null: false, foreign_key: false,                                                   type: :uuid, index: true
      t.references :portal,  null: false, foreign_key: { to_table: :help_center_portals, on_delete: :cascade }, type: :uuid, index: true
      # author_id references users table — the agent/user who authored this article
      t.references :author,  foreign_key: false, type: :uuid, index: true
      t.references :primary_category, foreign_key: { to_table: :help_center_categories, on_delete: :nullify }, type: :uuid, index: true, null: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :status]
      t.index [:portal_id, :position]
      t.index [:portal_id, :flags]
      t.index [:portal_id, :created_at]
      t.index [:portal_id, :article_type]
      t.index [:portal_id, :visibility]
    end
  end
end
