class CreateWallets < ActiveRecord::Migration[7.1]
  def change
    create_table :wallets, id: :uuid do |t|
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0
      t.string  :currency, limit: 4, null: false, default: "USD"

      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
  end
end

