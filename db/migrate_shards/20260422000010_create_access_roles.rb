class CreateAccessRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :access_roles, id: :uuid do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :name, null: false
      t.jsonb :permissions, default: {}, null: false
      t.boolean :is_system, default: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :access_roles, [:account_id, :name]
    add_index :access_roles, :created_at
  end
end
