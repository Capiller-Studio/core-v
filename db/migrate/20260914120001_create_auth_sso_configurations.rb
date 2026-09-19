# frozen_string_literal: true

class CreateAuthSsoConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_sso_configurations, id: :uuid do |t|
      t.references :account, type: :uuid, null: false, foreign_key: true, index: { unique: true, name: "index_auth_sso_configurations_on_account_id" }

      # Protocol & Provider
      t.integer  :protocol,      default: 0, null: false
      t.integer  :provider_type, default: 0, null: false

      # SAML 2.0 Configuration
      t.string   :idp_entity_id
      t.string   :idp_sso_url
      t.string   :idp_slo_url
      t.text     :idp_certificates, array: true, default: []
      t.string   :idp_metadata_url
      t.datetime :certificate_expires_at

      # OIDC Configuration
      t.string   :oidc_issuer
      t.string   :oidc_client_id
      t.string   :oidc_client_secret

      # Security & Governance Policies
      t.boolean  :enforce_sso,                   default: false, null: false
      t.boolean  :jit_provisioning_enabled,      default: true,  null: false
      t.boolean    :allow_owner_password_fallback, default: true,  null: false
      t.jsonb      :allowed_email_domains,         default: [],    null: false
      t.jsonb      :attribute_mapping,             default: {},    null: false
      t.integer    :session_timeout_seconds
      t.references :default_role, type: :uuid, foreign_key: false, null: true, index: { name: "index_auth_sso_configurations_on_default_role_id" }

      # Operational Status (0: inactive, 1: active, 2: test_mode)
      t.integer :status, default: 0, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }
    end

    add_index :auth_sso_configurations, :status, name: "index_auth_sso_configurations_on_status"
    add_index :auth_sso_configurations, :protocol, name: "index_auth_sso_configurations_on_protocol"
    add_index :auth_sso_configurations, :allowed_email_domains, using: :gin, name: "index_auth_sso_configurations_on_allowed_email_domains"
  end
end
