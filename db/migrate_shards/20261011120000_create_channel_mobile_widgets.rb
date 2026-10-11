# frozen_string_literal: true

class CreateChannelMobileWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_mobile_widgets, id: :uuid do |t|
      t.string  :name, null: false
      t.string  :identifier, null: false
      t.string  :secret, null: false

      t.jsonb   :configurations, default: {}, null: false
      t.jsonb   :ui_configurations, default: {}, null: false
      t.jsonb   :data, default: {}, null: false
      t.integer :flags, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.string  :default_locale, default: "en", null: false

      # --- Apple APNs (.p8 Token Auth) ---
      t.string  :ios_bundle_id
      t.text    :apns_key
      t.string  :apns_key_id
      t.string  :apns_team_id
      t.integer :apns_environment, default: 1, null: false

      # --- Google Firebase (FCM HTTP v1) ---
      t.string  :android_package_name
      t.text    :fcm_service_account
      t.string  :fcm_project_id

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :portal, type: :uuid, foreign_key: false, index: true
      t.references :pre_chat_form, type: :uuid, foreign_key: false, index: true
      t.references :fallback_channel, polymorphic: true, type: :uuid, index: { name: "index_mobile_widgets_on_fallback_channel" }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :identifier, unique: true
      t.index :status
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end

    create_table :channel_mobile_widget_translations, id: :uuid do |t|
      t.references :mobile_widget, null: false, foreign_key: { to_table: :channel_mobile_widgets }, type: :uuid, index: false
      t.string :locale, null: false
      t.string :header_title
      t.string :welcome_title
      t.string :welcome_tagline
      t.string :reply_time_text
      t.string :pre_chat_title
      t.string :pre_chat_subtitle

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:mobile_widget_id, :locale], unique: true, name: "index_cmwt_on_widget_and_locale"
    end
  end
end
