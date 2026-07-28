# frozen_string_literal: true

class CreateWebhookIncomings < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_incomings, id: :uuid do |t|
      # Where the webhook came from (e.g. "stripe", "facebook", "whatsapp")
      t.string :source, null: false, limit: 50

      # The specific event type within the source (e.g. "message", "charge.refunded")
      # Nullable — not all providers expose a top-level event type
      t.string :event_type, limit: 100

      # Full original URL, stored as text to handle long query strings and path params
      # Used by workers to recover route params (account_id, channel_id, etc.) via Rails router
      t.text :request_url

      t.jsonb :headers, null: false, default: {}
      t.jsonb :payload, null: false, default: {}

      t.integer :status,            null: false, default: 0
      t.integer :fail_safe_retries, null: false, default: 0
      t.text    :error_message

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:source, :status]
      t.index :created_at
    end
  end
end
