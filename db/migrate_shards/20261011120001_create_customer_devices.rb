# frozen_string_literal: true

class CreateCustomerDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_devices, id: :uuid do |t|
      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      t.references :customer, null: false, foreign_key: false, type: :uuid, index: true
      t.references :inbox, null: false, foreign_key: false, type: :uuid, index: true
      t.references :customer_inbox, null: false, foreign_key: false, type: :uuid, index: true

      t.string  :push_token, null: false
      t.integer :platform, null: false
      t.integer :push_provider, null: false
      t.integer :status, default: 0, null: false

      t.string  :device_identifier
      t.string  :device_model
      t.string  :os_version
      t.string  :app_version
      t.string  :sdk_version
      t.string  :locale
      t.string  :timezone
      t.datetime :last_seen_at
      t.datetime :last_push_at
      t.jsonb   :data, default: {}, null: false

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:inbox_id, :push_token], unique: true
      t.index [:customer_id, :status]
      t.index [:account_id, :created_at]
    end
  end
end
