class CreateMessageReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :message_reactions, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :message, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true
      t.references :sender, null: false, polymorphic: true, type: :uuid, index: true
      t.string :emoji, null: false
      t.string :reaction_name
      t.string :external_id

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :message_reactions, [:message_id, :sender_type, :sender_id, :emoji], unique: true, name: "idx_msg_reactions_unique"
    add_index :message_reactions, [:account_id, :created_at]
    add_index :message_reactions, [:account_id, :message_id]
  end
end
