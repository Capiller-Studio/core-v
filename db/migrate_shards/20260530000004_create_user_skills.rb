# frozen_string_literal: true

class CreateUserSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :user_skills, id: :uuid do |t|
      t.references :skill,   null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :user,    null: false, foreign_key: false, type: :uuid, index: true
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      # proficiency level:
      #   1 = beginner, 2 = intermediate, 3 = expert
      t.integer :proficiency, null: false, default: 1

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:user_id, :skill_id], unique: true, name: "idx_user_skill_unique"
    end
  end
end
