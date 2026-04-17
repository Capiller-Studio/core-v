class CreateSlaInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :sla_inboxes, id: :uuid do |t|
      t.references :account,    null: false, foreign_key: false,                     type: :uuid, index: true
      t.references :sla_policy, null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true
      t.references :inbox,      null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:sla_policy_id, :inbox_id], unique: true
    end
  end
end
