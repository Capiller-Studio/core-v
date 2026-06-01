# frozen_string_literal: true

class CreateAssignmentPolicyInboxes < ActiveRecord::Migration[8.1]
  def change
    create_table :assignment_policy_inboxes, id: :uuid do |t|
      t.references :assignment_policy, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :inbox,             null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.references :account,           null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:assignment_policy_id, :inbox_id], unique: true, name: "idx_ap_inbox_unique"
    end
  end
end
