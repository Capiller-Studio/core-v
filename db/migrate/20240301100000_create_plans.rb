class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.string  :name, null: false
      t.integer :status, null: false, default: 0
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :annual_price, precision: 10, scale: 2, null: false, default: 0
      t.string  :currency, limit: 4, null: false, default: "USD"
      t.jsonb   :features, null: false, default: {}
      t.jsonb   :limits, null: false, default: {}
      t.integer :trial_days, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.integer :visibility, null: false, default: 0

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:name, :currency], unique: true
      t.index :status
      t.index :position
      t.index :visibility
    end
  end
end
