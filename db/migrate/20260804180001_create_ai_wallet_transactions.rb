class CreateAiWalletTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_wallet_transactions, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: false, index: true
      t.references :ai_wallet, type: :uuid, null: false, foreign_key: true, index: true
      t.references :user, type: :uuid, null: true, foreign_key: false
      t.integer :transaction_type, null: false
      t.integer :amount, null: false
      t.integer :balance_after, null: false
      t.string :action_type
      t.string :model_used
      t.string :description
      t.jsonb :data, default: {}, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :created_at]
      t.index [:ai_wallet_id, :created_at]
    end
  end
end
