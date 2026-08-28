class CreateChannelCustoms < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_customs, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid
      t.string :name
      t.string :description
      t.string :identifier, null: false
      t.integer :status, default: 0, null: false
      
      # Outbound Webhook
      t.string :webhook_url
      t.string :webhook_secret, null: false
      t.jsonb :headers, default: {}, null: false
      
      # Inbound Webhook
      t.string :hmac_token, null: false
      t.jsonb :response_mapping, default: {}, null: false
      
      # Storage
      t.jsonb :configurations, default: {}, null: false
      t.jsonb :data, default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :channel_customs, [:account_id, :identifier], unique: true
    add_index :channel_customs, [:account_id, :created_at]
    add_index :channel_customs, [:account_id, :status]
  end
end
