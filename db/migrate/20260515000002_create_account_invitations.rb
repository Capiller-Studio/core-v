# frozen_string_literal: true

class CreateAccountInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :account_invitations, id: :uuid do |t|
      t.string     :email,          null: false
      t.string     :token,          null: false
      t.uuid       :role_ids,       null: false, array: true, default: []
      t.references :account,        null: false, type: :uuid, index: true, foreign_key: { on_delete: :cascade }
      t.references :invited_by,     type: :uuid, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer    :status,         null: false, default: 0
      t.datetime   :expires_at,     null: false
      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :account_invitations, [:account_id, :email], unique: true, where: "status = 0"
    add_index :account_invitations, :token, unique: true
    add_index :account_invitations, :status
  end
end
