# frozen_string_literal: true

class CreateChannelFacebookPages < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_facebook_pages, id: :uuid do |t|
      # --- Identity ---
      t.string  :page_identifier, null: false          # Facebook Page ID (numeric string)
      t.string  :name                                   # Page display name
      t.string  :avatar_url                             # Page profile picture URL

      # --- Authentication ---
      t.string  :access_token, null: false              # Long-lived Page Access Token (permanent — never expires)
      t.string  :user_access_token                      # Long-lived User Access Token (60-day, used for token refresh)

      # --- Configuration ---
      t.jsonb   :configurations, null: false, default: {} # CSAT, SLA, greeting, etc.
      t.jsonb   :data, null: false, default: {}           # Extra metadata from Graph API

      # --- Status ---
      t.integer :status, default: 0, null: false          # enum: active, disconnected

      # --- Relations ---
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      # --- Indexes ---
      t.index :status
      t.index [:account_id, :name]
      t.index :page_identifier
      t.index [:account_id, :page_identifier], unique: true
      t.index [:account_id, :created_at]
    end
  end
end
