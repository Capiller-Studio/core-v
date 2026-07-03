class CreateChannelApis < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_apis, id: :uuid do |t|
      t.string  :identifier, null: false
      t.string  :name
      t.text    :description
      t.string  :webhook_url
      t.string  :webhook_secret, null: false
      t.string  :hmac_token
      t.jsonb   :configurations,         default: {}, null: false
      t.jsonb   :data,                   default: {}, null: false
      t.integer :status, default: 0, null: false

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps  default: -> { "CURRENT_TIMESTAMP" }

      t.index :status
      t.index [:account_id, :identifier], unique: true
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
