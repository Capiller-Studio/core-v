class CreateHelpCenterCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_categories, id: :uuid do |t|
      t.integer :ancestry_depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0
      t.jsonb   :configurations, null: false, default: {}
      t.string  :ancestry
      t.integer :position
      t.string  :icon_key                                 # Key from predefined icon set e.g. "book-open" (rendered per-app via Lucide)

      # visibility: everyone (0) — visible to all, unlisted (1) — accessible via link only, internal (2) — agents only
      t.integer :visibility, null: false, default: 0
      t.integer :status,     null: false, default: 0

      # flags (FlagShihTzu bit fields):
      #   1 => :guide_mode — render articles in this category as sequential steps with Next/Previous navigation
      #                       and a step progress indicator (e.g. "Step 2 of 5")
      t.integer :flags, null: false, default: 0

      t.references :account, null: false, foreign_key: false,                                                 type: :uuid, index: true
      t.references :portal,  null: false, foreign_key: { to_table: :help_center_portals, on_delete: :cascade}, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :status]
      t.index [:portal_id, :ancestry]
      t.index [:portal_id, :position]
      t.index [:portal_id, :flags]
      t.index [:portal_id, :created_at]
      t.index [:portal_id, :visibility]
    end
  end
end
