class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains, id: :uuid do |t|
      t.string   :name, default: ""
      t.string   :value, null: false
      t.integer  :domain_type,     null: false, default: 0    # subdomain: 0, custom: 1
      t.integer  :status,          null: false, default: 0    # active: 0, inactive: 1, suspended: 2

      # DNS verification
      t.integer  :dns_status,      null: false, default: 0    # unverified: 0, pending: 1, verified: 2, failed: 3
      t.datetime :dns_verified_at
      t.string   :cname_target,    default: ""

      # SSL certificate tracking
      t.integer  :ssl_status,      null: false, default: 0    # none: 0, pending: 1, active: 2, expired: 3, failed: 4
      t.datetime :ssl_added_at
      t.datetime :ssl_expires_at

      # Verification tracking
      t.datetime :last_checked_at

      t.references :account, null: false, foreign_key: { on_delete: :cascade }, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index :value, unique: true
      t.index :status
      t.index :domain_type
      t.index :dns_status
      t.index :ssl_status
      t.index [:account_id, :created_at]
      t.index [:account_id, :domain_type]
    end
  end
end
