# frozen_string_literal: true

class CreateAccountPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :account_plans, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.references :plan,    type: :uuid, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :plan_id], unique: true
    end
  end
end
