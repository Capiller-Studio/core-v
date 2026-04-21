class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string  :code, null: false
      t.integer :transaction_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string  :currency, limit: 4, null: false, default: "USD"
      t.integer :provider, null: false, default: 0
      t.string  :external_id
      t.string  :description
      t.jsonb   :data, null: false, default: {}

      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true
      t.references :subscription, null: true, type: :uuid, foreign_key: { on_delete: :nullify }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :code, unique: true
      t.index :status
      t.index :transaction_type
      t.index :external_id
      t.index :created_at
    end
  end
end
