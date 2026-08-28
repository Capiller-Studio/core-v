class CreateAffiliatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_payouts, id: :uuid do |t|
      t.string :code, null: false
      t.references :affiliate_profile, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :payout_batch, foreign_key: { to_table: :affiliate_payout_batches, on_delete: :nullify }, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false
      t.integer :provider, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.string :external_id
      t.jsonb :data, default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :affiliate_payouts, :code, unique: true
    add_index :affiliate_payouts, :status
    add_index :affiliate_payouts, :created_at
    add_index :affiliate_payouts, :external_id
  end
end
