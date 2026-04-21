class CreateIdentities < ActiveRecord::Migration[7.1]
  def change
    create_table :identities, id: :uuid do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :name
      
      t.string :identifier, null: false
      t.string :external_id
      t.string :administration_url

      t.jsonb :configurations,    null: false, default: {}
      t.jsonb :custom_attributes, null: false, default: {}
      t.jsonb :raw_response,      null: false, default: {}
      t.integer :identity_type,   null: false, default: 0

      t.references :account,         null: false, foreign_key: false, type: :uuid, index: true
      t.references :address,         null: true,  foreign_key: false, type: :uuid, index: false
      t.references :customer,        null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :identity_source, null: true, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name]
      t.index [:account_id, :external_id]
      t.index [:customer_id, :identity_source_id], unique: true
      t.index [:account_id, :identifier],          unique: true
      t.index [:account_id, :created_at]
    end
  end
end
