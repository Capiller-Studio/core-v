# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

class CreateSystemLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_logs, id: :uuid do |t|
      t.references :account, type: :uuid, null: true, index: true, foreign_key: false

      t.string  :event_key,  null: false, index: true
      t.integer :log_level,  null: false, default: 0, index: true # 0: info, 1: warn, 2: error, 3: debug
      t.text    :message

      t.jsonb   :payload,    null: false, default: {}
      t.jsonb   :metadata,   null: false, default: {}

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :system_logs, [:account_id, :created_at], name: "index_system_logs_on_account_and_created_at"
    add_index :system_logs, [:event_key, :created_at], name: "index_system_logs_on_event_key_and_created_at"
  end
end
