# frozen_string_literal: true

class CreatePlatformRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_roles, id: :uuid do |t|
      t.string :name,       null: false
      t.string :identifier, null: false
      t.jsonb  :permissions, null: false, default: {}

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :platform_roles, :identifier, unique: true
    add_index :platform_roles, :name
  end
end
