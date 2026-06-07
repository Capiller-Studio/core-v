class CreateHelpCenterPortals < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_portals, id: :uuid do |t|
      t.string  :name
      t.jsonb   :configurations,    default: {}, null: false
      t.jsonb   :ui_configurations, default: {}, null: false
      t.string  :locales,           array: true, null: false, default: ["en"]
      t.string  :default_locale,    null: false, default: "en"
      t.integer :status,            null: false, default: 0
      t.integer :flags,             null: false, default: 0

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :domain,  null: false, foreign_key: false, type: :uuid, index: { unique: true }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :status]
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
      t.index [:account_id, :default_locale]
    end

    add_reference :channel_web_widgets, :portal, type: :uuid, index: true, foreign_key: { to_table: :help_center_portals, on_delete: :nullify }
  end
end
