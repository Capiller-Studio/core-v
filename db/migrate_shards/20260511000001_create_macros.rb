class CreateMacros < ActiveRecord::Migration[8.1]
  def change
    create_table :macros, id: :uuid do |t|
      t.string  :name,        null: false
      t.text    :description

      # Ordered list of actions to execute.
      # Same JSONB structure as automations.actions — shared via Actionable concern.
      # [
      #   { "action": "assign_agent", "params": { "agent_id": "uuid" } },
      #   { "action": "set_priority", "params": { "priority": "urgent" } }
      # ]
      t.jsonb   :actions,     null: false, default: []

      # active (0) — can be executed, inactive (1) — disabled
      t.integer :status,      null: false, default: 0

      # Visibility scope:
      #   account_wide (0) — accessible by all agents in the account
      #   personal (1)     — only the owning user can see/execute
      #   team (2)         — all members of the assigned team can see/execute
      t.integer :visibility,  null: false, default: 0

      # Bitwise flags (FlagShihTzu). Reserved for future use.
      t.integer :flags,       null: false, default: 0

      # System macros are non-deletable, created by the platform.
      t.boolean :is_system,   null: false, default: false

      # Polymorphic scope owner:
      #   visibility: :personal     → scopeable_type: "User", scopeable_id: user.id
      #   visibility: :team         → scopeable_type: "Team", scopeable_id: team.id
      #   visibility: :account_wide → scopeable_type: nil,    scopeable_id: nil
      # Extensible: can later add "Inbox", "Department", etc. without migration.
      t.references :scopeable, polymorphic: true, type: :uuid

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:account_id, :visibility]
      t.index [:account_id, :scopeable_type, :scopeable_id], name: "idx_macros_scopeable"
      t.index [:account_id, :name]
      t.index [:account_id, :is_system]
      t.index [:account_id, :status]
      t.index :created_at
    end
  end
end
