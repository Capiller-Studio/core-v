class CreateWalletTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :wallet_transactions, id: :uuid do |t|
      t.integer :transaction_type, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :balance_after, precision: 10, scale: 2, null: false
      t.string  :currency, limit: 4, null: false, default: "USD"
      t.string  :description

      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true
      t.references :wallet, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true
      t.references :reference, polymorphic: true, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :transaction_type
      t.index :created_at
    end
  end
end
