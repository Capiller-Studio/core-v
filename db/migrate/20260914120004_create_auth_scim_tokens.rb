# frozen_string_literal: true

class CreateAuthScimTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_scim_tokens, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true, index: { name: "index_auth_scim_tokens_on_account_id" }

      t.string   :token_digest,    null: false
      t.string   :token_last_four
      t.string   :name,            null: false
      t.datetime :last_used_at
      t.datetime :expires_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :auth_scim_tokens, :token_digest, unique: true, name: "index_auth_scim_tokens_on_token_digest"
    add_index :auth_scim_tokens, [:account_id, :created_at], name: "index_auth_scim_tokens_on_account_and_created"
  end
end
