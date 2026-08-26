class CreateAffiliatePayoutBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliate_payout_batches, id: :uuid do |t|
      t.string :code, null: false
      t.string :name
      t.integer :status, default: 0, null: false
      t.integer :provider, default: 0, null: false
      t.string :external_id
      t.decimal :total_amount, precision: 12, scale: 2, default: 0
      t.datetime :funded_at
      t.jsonb :data, default: {}

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :affiliate_payout_batches, :code, unique: true
    add_index :affiliate_payout_batches, :status
    add_index :affiliate_payout_batches, :external_id
    add_index :affiliate_payout_batches, :created_at
  end
end

