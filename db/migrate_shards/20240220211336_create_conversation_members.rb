class CreateConversationMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_members, id: :uuid do |t|
      t.datetime :last_activity_at
      t.datetime :last_seen_at
      t.integer  :role, null: false, default: 0

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :conversation,   null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :member,         null: false, polymorphic: true,                     type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:conversation_id, :member_id], unique: true
      t.index [:conversation_id, :role]
    end
  end
end
