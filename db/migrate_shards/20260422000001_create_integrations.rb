class CreateIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :integrations, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.string :name
      t.integer :provider, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :settings, default: {}, null: false
      t.jsonb :credentials, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :integrations, [:account_id, :provider]
    add_index :integrations, [:account_id, :status]
    add_index :integrations, [:account_id, :created_at]
  end
end
