class CreateAffiliateCommissions < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_commissions, id: :uuid do |t|
      t.references :affiliate_profile, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :affiliate_referral, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :transaction_record, null: false, foreign_key: { to_table: :transactions, on_delete: :cascade }, type: :uuid
      t.references :original_commission, foreign_key: { to_table: :affiliate_commissions, on_delete: :nullify }, type: :uuid
      
      t.decimal :original_amount, null: false, precision: 10, scale: 2
      t.string  :original_currency, null: false
      t.decimal :exchange_rate, precision: 10, scale: 6, default: 1.0
      
      # The final actual calculation inside the Affiliate's currency mapped mathematically 
      t.decimal :amount, null: false, precision: 10, scale: 2
      
      t.integer :commission_type, default: 0
      t.integer :status, default: 0

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :affiliate_commissions, :status
    add_index :affiliate_commissions, :commission_type
    add_index :affiliate_commissions, :created_at
  end
end
