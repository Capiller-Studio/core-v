class CreateAffiliatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_payouts, id: :uuid do |t|
      t.references :affiliate_profile, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, default: 0
      t.jsonb :data, default: {}

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end
    
    add_index :affiliate_payouts, :status
    add_index :affiliate_payouts, :created_at
  end
end
