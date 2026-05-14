# frozen_string_literal: true

class CreatePlatformComments < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_comments, id: :uuid do |t|
      t.text :content, null: false
      t.references :staff,       null: false, foreign_key: { to_table: :platform_staffs, on_delete: :cascade }, type: :uuid
      t.references :commentable, null: false, polymorphic: true, type: :uuid

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :platform_comments, [:commentable_type, :commentable_id]
  end
end
