# frozen_string_literal: true

class CreateSkills < ActiveRecord::Migration[8.1]
  def change
    create_table :skills, id: :uuid do |t|
      t.string  :name,       null: false
      # skill_type categorizes skills for UI grouping and filtering:
      #   0 = general, 1 = language, 2 = product, 3 = technical
      t.integer :skill_type, null: false, default: 0
      t.text    :description
      t.integer :status,     null: false, default: 0  # active: 0, inactive: 1

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :name], unique: true
      t.index [:account_id, :skill_type]
    end
  end
end
