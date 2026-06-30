# frozen_string_literal: true

class CreateChannelInstagram < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_instagram, id: :uuid do |t|
      # --- Identity ---
      t.string  :instagram_id, null: false              # Instagram User ID (numeric string)
      t.string  :username                                # Instagram username (@handle)
      t.string  :name                                    # Display name
      t.string  :avatar_url                              # Profile picture URL

      # --- Authentication ---
      t.string  :access_token, null: false               # Long-lived IG Access Token (60-day, refreshable indefinitely)
      t.datetime :expires_at, null: false                # Token expiration timestamp

      # --- Configuration ---
      t.jsonb   :configurations, null: false, default: {} # CSAT, SLA, greeting, etc.
      t.jsonb   :data, null: false, default: {}           # Extra metadata from Instagram API

      # --- Status ---
      t.integer :status, default: 0, null: false          # enum: active, disconnected

      # --- Relations ---
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      # --- Indexes ---
      t.index :status
      t.index :instagram_id, unique: true
      t.index [:account_id, :instagram_id], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
