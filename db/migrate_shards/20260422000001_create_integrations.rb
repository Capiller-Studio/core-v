class CreateIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :integrations, id: :uuid do |t|
      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true
      t.integer :provider, null: false
      t.jsonb :settings, default: {}
      t.boolean :active, default: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :integrations, [:account_id, :provider], unique: true
    add_index :integrations, :created_at
  end
end
