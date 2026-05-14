# frozen_string_literal: true

class CreatePlatformStaffRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_staff_roles, id: :uuid do |t|
      t.references :staff, null: false, foreign_key: { to_table: :platform_staffs, on_delete: :cascade }, type: :uuid
      t.references :role,  null: false, foreign_key: { to_table: :platform_roles, on_delete: :cascade }, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :platform_staff_roles, [:staff_id, :role_id], unique: true
  end
end
