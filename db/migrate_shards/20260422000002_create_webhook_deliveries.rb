class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries, id: :uuid do |t|
      t.references :integration, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :event_name, null: false
      t.string :endpoint_url, null: false
      t.jsonb :request_payload, default: {}
      t.integer :status, default: 0

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :event_name
    add_index :webhook_deliveries, :created_at
  end
end
