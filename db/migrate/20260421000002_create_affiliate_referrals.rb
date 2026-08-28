class CreateAffiliateReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_referrals, id: :uuid do |t|
      t.references :affiliate_profile, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: { unique: true }
      t.integer :status, default: 0, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :affiliate_referrals, :status
    add_index :affiliate_referrals, :created_at
    add_index :affiliate_referrals, [:affiliate_profile_id, :status]
    add_index :affiliate_referrals, [:affiliate_profile_id, :created_at]
  end
end
