# frozen_string_literal: true

class CreateAuthDomainVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_domain_verifications, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true, index: { name: "index_auth_domain_verifications_on_account_id" }

      t.string   :domain,             null: false
      t.string   :verification_token, null: false
      t.integer  :status,             default: 0, null: false
      t.datetime :verified_at
      t.datetime :last_checked_at
      t.integer  :check_count,        default: 0, null: false
      t.string   :failure_reason

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :auth_domain_verifications, :domain, unique: true, name: "index_auth_domain_verifications_on_domain"
    add_index :auth_domain_verifications, [:account_id, :created_at], name: "index_auth_domain_verifications_on_account_and_created"
    add_index :auth_domain_verifications, :status, name: "index_auth_domain_verifications_on_status"
  end
end
