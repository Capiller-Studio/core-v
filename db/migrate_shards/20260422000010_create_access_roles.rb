class CreateAccessRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :access_roles, id: :uuid do |t|
      t.references :account,  null: false, foreign_key: false, type: :uuid, index: true
      t.string :name, null: false
      t.string :identifier, null: false
      t.jsonb :permissions, default: {}, null: false
      t.boolean :is_system, default: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :access_roles, [:account_id, :name]
    add_index :access_roles, [:account_id, :identifier], unique: true
    add_index :access_roles, :created_at
  end
end
