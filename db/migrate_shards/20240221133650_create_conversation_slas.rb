class CreateConversationSlas < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_slas, id: :uuid do |t|
      t.integer    :status, null: false, default: 0

      t.references :account,         null: false, foreign_key: false,                     type: :uuid, index: true
      t.references :sla_policy,      null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true
      t.references :conversation,    null: false, foreign_key: { on_delete: :cascade },   type: :uuid, index: true

      t.datetime   :target_first_response_at
      t.datetime   :target_next_response_at
      t.datetime   :target_resolution_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:conversation_id, :sla_policy_id], unique: true
      t.index [:account_id, :status]
      t.index [:account_id, :created_at]
      t.index :target_first_response_at
      t.index :target_next_response_at
      t.index :target_resolution_at
    end
  end
end
