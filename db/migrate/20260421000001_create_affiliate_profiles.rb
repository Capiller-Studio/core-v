class CreateAffiliateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :affiliate_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :referral_code, null: false
      t.decimal :commission_rate, precision: 5, scale: 2
      t.integer :tenure_months
      t.decimal :max_earnings_per_account, precision: 10, scale: 2
      t.integer :holding_days
      t.string :currency, default: "USD", null: false
      t.jsonb :bank_account_data, default: {}

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
    
    add_index :affiliate_profiles, :referral_code, unique: true
    add_index :affiliate_profiles, :currency
    add_index :affiliate_profiles, :created_at
  end
end
