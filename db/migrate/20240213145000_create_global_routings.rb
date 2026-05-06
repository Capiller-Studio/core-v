class CreateGlobalRoutings < ActiveRecord::Migration[7.1]
  def change
    create_table :global_routings, id: :uuid do |t|
      t.string :route_type,  null: false
      t.string :route_value, null: false
      t.string :shard_key,   null: false
      t.references :account, null: false, type: :uuid, index: true, foreign_key: { on_delete: :cascade }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:route_type, :route_value], unique: true, name: "index_global_routings_on_type_and_value"
    end
  end
end
