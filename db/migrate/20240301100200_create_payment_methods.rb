class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.integer :provider, null: false, default: 0
      t.integer :payment_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.string  :last_four
      t.string  :brand
      t.integer :expiry_month
      t.integer :expiry_year
      t.string  :external_id
      t.jsonb   :data, null: false, default: {}

      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :external_id
      t.index [:account_id, :is_default]
    end
  end
end
