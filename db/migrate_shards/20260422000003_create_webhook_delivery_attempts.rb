class CreateWebhookDeliveryAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_delivery_attempts, id: :uuid do |t|
      t.references :webhook_delivery, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.integer :attempt_number, null: false, default: 1
      t.integer :http_status
      t.text :response_body
      t.text :error_trace

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :webhook_delivery_attempts, :created_at
  end
end
