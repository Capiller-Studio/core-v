class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates, id: :uuid do |t|
      t.string :from_currency, null: false
      t.string :to_currency, null: false
      t.decimal :rate, precision: 10, scale: 6, null: false
      
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
      
      t.index [:from_currency, :to_currency], unique: true
      t.index :created_at
    end
  end
end
