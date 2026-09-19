# frozen_string_literal: true

class CreateAuthAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_audit_logs, id: :uuid do |t|
      t.references :account, type: :uuid, null: true, foreign_key: true, index: { name: "index_auth_audit_logs_on_account_id" }
      t.references :user,    type: :uuid, null: true, foreign_key: true, index: { name: "index_auth_audit_logs_on_user_id" }

      t.integer  :event_type,    null: false
      t.integer  :auth_method,   null: false
      t.integer  :status,        null: false
      t.string   :email
      t.string   :ip_address
      t.string   :user_agent
      t.string   :error_code
      t.string   :error_message
      t.jsonb    :metadata,      default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :auth_audit_logs, [:account_id, :created_at], name: "index_auth_audit_logs_on_account_and_created"
    add_index :auth_audit_logs, [:user_id, :created_at], name: "index_auth_audit_logs_on_user_and_created"
    add_index :auth_audit_logs, :event_type, name: "index_auth_audit_logs_on_event_type"
    add_index :auth_audit_logs, :status, name: "index_auth_audit_logs_on_status"
    add_index :auth_audit_logs, :email, name: "index_auth_audit_logs_on_email"
    add_index :auth_audit_logs, :created_at, name: "index_auth_audit_logs_on_created_at"
  end
end
