class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages, id: :uuid do |t|
      # t.integer :message_type, null: false, default: Message.message_types[] TODO: WIP
      t.text     :content
      t.integer  :source
      t.string   :external_id
      t.string   :external_reply_to_id
      t.datetime :edited_at
      t.datetime :deleted_at

      t.integer :status,       null: false, default: 0
      t.integer :content_type, null: false, default: Message.content_types[:text]
      t.integer :visibility,   null: false, default: Message.visibilities[:global]

      t.jsonb  :configurations, default: {}, null: false
      t.jsonb  :data,           default: {}, null: false
      t.jsonb  :ai_metadata,    default: {}, null: false
      t.jsonb  :edit_history,    default: [], null: false
      t.string :locale

      t.references :account,        null: false, foreign_key: false,                    type: :uuid, index: true
      t.references :inbox,          null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :conversation,   null: false, foreign_key: { on_delete: :cascade },  type: :uuid, index: true
      t.references :sender,         null: false, polymorphic: true,                     type: :uuid, index: true
      t.references :outbound_channel, null: true, polymorphic: true, type: :uuid, index: true
      t.references :reply_to_message, null: true, foreign_key: { to_table: :messages, on_delete: :nullify }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :external_id]
      t.index [:conversation_id, :status]
      t.index [:conversation_id, :content_type]
      t.index [:conversation_id, :created_at]
      t.index [:conversation_id, :deleted_at]
      t.index [:conversation_id, :sender_type, :created_at], name: "index_messages_on_conv_and_sender_and_created_at"
      t.index :ai_metadata, using: :gin
    end
  end
end
