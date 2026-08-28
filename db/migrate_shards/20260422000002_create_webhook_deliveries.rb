class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :resource, polymorphic: true, null: false, type: :uuid, index: true
      t.string :event_name, null: false
      t.string :endpoint_url, null: false
      t.jsonb :request_payload, default: {}, null: false
      t.integer :status, default: 0, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :webhook_deliveries, [:account_id, :created_at]
    add_index :webhook_deliveries, [:account_id, :status]
    add_index :webhook_deliveries, [:resource_type, :resource_id, :status], name: "index_webhook_deliveries_on_resource_and_status"
    add_index :webhook_deliveries, [:resource_type, :resource_id, :created_at], name: "index_webhook_deliveries_on_resource_and_created_at"
    add_index :webhook_deliveries, :event_name
  end
end
