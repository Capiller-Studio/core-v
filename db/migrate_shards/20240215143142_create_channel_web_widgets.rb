class CreateChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_web_widgets, id: :uuid do |t|
      t.string  :name
      t.string  :website_url
      t.jsonb   :configurations, default: {}, null: false
      t.jsonb   :ui_configurations, default: {}, null: false
      t.jsonb   :data, default: {}, null: false
      t.string  :secret, null: false
      t.integer :flags, default: 0, null: false
      t.integer :status, default: 0, null: false

      t.string  :default_locale, default: "en", null: false

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :portal, type: :uuid, index: true, foreign_key: { to_table: :portals, on_delete: :nullify }
      t.references :pre_chat_form, type: :uuid, index: true, foreign_key: { to_table: :channel_contact_forms, on_delete: :nullify }
      t.references :fallback_channel, polymorphic: true, type: :uuid, index: { name: 'index_web_widgets_on_fallback_channel' }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :name]
      t.index :website_url
      t.index [:account_id, :created_at]
    end

    create_table :channel_web_widget_translations, id: :uuid do |t|
      t.references :web_widget, null: false, foreign_key: { to_table: :channel_web_widgets }, type: :uuid, index: false
      t.string :locale, null: false
      
      t.string :launcher_text
      t.string :reply_time_text
      t.string :pre_chat_title
      t.string :pre_chat_subtitle
      t.string :welcome_title
      t.string :welcome_tagline
      
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index [:web_widget_id, :locale], unique: true, name: 'index_cwwt_on_widget_and_locale'
    end
  end
end
