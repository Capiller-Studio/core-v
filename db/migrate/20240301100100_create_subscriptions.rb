class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.integer  :status, null: false, default: 0
      t.integer  :billing_cycle, null: false, default: 0
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :trial_end_at
      t.datetime :cancelled_at
      t.string   :external_id
      t.integer  :provider, null: false, default: 0
      t.integer  :quantity, null: false, default: 1
      t.string   :currency, limit: 4, null: false, default: "USD"
      t.jsonb    :data, null: false, default: {}

      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true
      t.references :plan, null: false, type: :uuid, foreign_key: { on_delete: :restrict }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index :external_id
      t.index :current_period_end
      t.index :trial_end_at
      t.index [:account_id, :status]
      t.index :account_id, unique: true, where: "status IN (0, 1)", name: "idx_uniq_active_subscription_account"
    end
  end
end
