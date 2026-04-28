class CreateAccessAccountUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :access_account_user_roles, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :account_user, null: false, foreign_key: false, type: :uuid, index: true
      t.references :role, null: false, foreign_key: { to_table: :access_roles, on_delete: :cascade }, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :access_account_user_roles, [:account_user_id, :role_id], name: "idx_acc_user_role_composite"
    add_index :access_account_user_roles, :created_at
  end
end
