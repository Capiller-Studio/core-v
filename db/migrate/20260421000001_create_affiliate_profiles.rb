class CreateAffiliateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: { unique: true }
      t.string :referral_code, null: false
      t.decimal :commission_rate, precision: 5, scale: 2
      t.integer :tenure_months
      t.decimal :max_earnings_per_account, precision: 10, scale: 2
      t.integer :holding_days
      t.string :currency, default: "USD", null: false
      t.boolean :payouts_enabled, default: false, null: false
      t.integer :payment_method_type, default: 0, null: false
      t.jsonb :payment_details, default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
    
    add_index :affiliate_profiles, :referral_code, unique: true
    add_index :affiliate_profiles, :currency
    add_index :affiliate_profiles, :created_at
  end
end
