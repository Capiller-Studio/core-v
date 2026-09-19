# frozen_string_literal: true

class CreateAuthUserIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_user_identities, id: :uuid do |t|
      t.references :user,    type: :uuid, null: false, foreign_key: true, index: { name: "index_auth_user_identities_on_user_id" }
      t.references :account, type: :uuid, null: true,  foreign_key: true, index: { name: "index_auth_user_identities_on_account_id" }

      t.integer  :provider,         null: false
      t.string   :uid,              null: false
      t.string   :email
      t.jsonb    :credentials,      default: {}, null: false
      t.jsonb    :extra_attributes, default: {}, null: false
      t.datetime :last_used_at

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :auth_user_identities, [:provider, :uid], unique: true, name: "index_auth_user_identities_on_provider_and_uid"
    add_index :auth_user_identities, [:user_id, :provider], name: "index_auth_user_identities_on_user_and_provider"
    add_index :auth_user_identities, [:account_id, :provider], name: "index_auth_user_identities_on_account_and_provider"
    add_index :auth_user_identities, :email, name: "index_auth_user_identities_on_email"

    # Drop deprecated single-provider columns from users table in favor of auth_user_identities
    remove_index :users, [:provider, :provider_uid], unique: true, name: "index_users_on_provider_and_provider_uid"
    remove_column :users, :provider, :string
    remove_column :users, :provider_uid, :string
  end
end
