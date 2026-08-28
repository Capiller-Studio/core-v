class CreateAiCreditGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_credit_grants, id: :uuid do |t|
      t.references :ai_wallet, type: :uuid, null: false, foreign_key: true, index: true
      t.integer  :amount,      null: false
      t.integer  :balance,     null: false
      t.integer  :grant_type,  null: false, default: 0 # enum: monthly_free, purchased
      t.datetime :expires_at,  null: false
      t.string   :description
      t.jsonb    :data, default: {}, null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index [:ai_wallet_id, :expires_at]
      t.index [:ai_wallet_id, :created_at]
    end
  end
end
