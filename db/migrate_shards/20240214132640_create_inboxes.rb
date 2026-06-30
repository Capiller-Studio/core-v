class CreateInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :inboxes, id: :uuid do |t|
      t.string  :name, null: false, default: ""
      t.string  :display_name
      t.integer :status, null: false, default: 0
      t.integer :flags, null: false, default: 0
      t.jsonb   :configurations, null: false, default: {}

      t.string :timezone, null: false, default: "UTC"
      t.string :default_locale, null: false, default: "en"
      t.boolean :primary_inbox, null: false, default: false
      t.integer :reopen_window_seconds, null: false, default: 0

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      # t.references :address, null: true,  foreign_key: false, type: :uuid, index: false
      t.references :channel, polymorphic: true, null: false, type: :uuid, index: true
      t.references :business_hour_group, null: true, foreign_key: { on_delete: :nullify }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :status]
      t.index [:account_id, :created_at]
      t.index [:channel_type, :channel_id], unique: true, where: "primary_inbox = true", name: "index_inboxes_on_channel_primary"
    end
  end
end
