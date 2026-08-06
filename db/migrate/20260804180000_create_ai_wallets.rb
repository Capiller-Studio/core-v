class CreateAiWallets < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_wallets, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true, index: { unique: true, name: "index_ai_wallets_on_account_id_unique" }
      t.integer :balance, null: false, default: 0
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end
