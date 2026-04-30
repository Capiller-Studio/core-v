class CreateHelpCenterRedirects < ActiveRecord::Migration[7.1]
  def change
    create_table :help_center_redirects, id: :uuid do |t|
      # source_path and target_path store URL path segments (without domain)
      # e.g. source_path: "setup-whatsapp-v1", target_path: "setup-whatsapp-channel"
      # Used to preserve SEO and bookmarked links when article slugs change
      t.string  :source_path, null: false
      t.string  :target_path, null: false
      t.string  :locale       # nil = applies to all locales; set to specific locale (e.g. "es") if locale-specific
      t.integer :status_code, null: false, default: 301 # 301 = permanent, 302 = temporary

      t.references :portal, null: false, type: :uuid,
                   foreign_key: { to_table: :help_center_portals, on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:portal_id, :source_path, :locale], unique: true
    end
  end
end
