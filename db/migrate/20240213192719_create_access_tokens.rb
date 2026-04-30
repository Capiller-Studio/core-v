class CreateAccessTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :access_tokens, id: :uuid do |t|
      t.string   :token,             null: false
      t.integer  :flags,             null: false, default: 0
      t.boolean  :destroy_after_use, null: false, default: false
      t.datetime :valid_till

      # token_type distinguishes usage:
      #   api_key (0)    — long-lived API authentication token (default)
      #   magic_link (1) — short-lived, one-time-use token for customer portal login
      t.integer :token_type, null: false, default: 0

      t.references :owner, polymorphic: true, null: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :token, unique: true
      t.index :created_at
      t.index :token_type
    end
  end
end
