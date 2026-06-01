# frozen_string_literal: true

class CreateAssignmentPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :assignment_policies, id: :uuid do |t|
      t.string  :name,            null: false
      t.text    :description

      # strategy determines how conversations are distributed:
      #   round_robin (0)   — rotate evenly across eligible agents
      #   load_balanced (1) — assign to agent with fewest open conversations
      #   skills_based (2)  — match required skills, then load-balance among matches
      #   manual (3)        — no auto-assign; agents self-serve from queue
      t.integer :strategy,        null: false, default: 0

      t.integer :status,          null: false, default: 0  # active: 0, inactive: 1
      t.integer :position                                   # ordering among same-scope policies

      # flags (FlagShihTzu bit fields):
      #   1 => :consider_agent_skills  — enable skills matching for this policy
      #   2 => :allow_idle_reassignment — enable idle-timeout reassignment
      #   3 => :notify_on_assignment   — send notification to assigned agent
      #   4 => :notify_team_leads      — notify team leads on assignment
      t.integer :flags,           null: false, default: 0

      # --- Capacity ---
      t.integer :max_conversations_per_agent  # nil = unlimited

      # --- Business Hours ---
      t.boolean :respect_business_hours, null: false, default: false
      t.references :business_hour_group, null: true, foreign_key: { on_delete: :nullify }, type: :uuid

      # --- Reassignment ---
      t.boolean :reassign_on_offline,    null: false, default: false
      t.integer :idle_timeout_minutes    # reassign after agent idle N minutes

      # --- Priority routing ---
      # When true, urgent > high > medium > low conversations are assigned first
      t.boolean :prioritize_by_conversation_priority, null: false, default: false

      # --- Conditions (same JSONB schema as Automations) ---
      # Filter which conversations this policy applies to.
      # e.g., only VIP customers, only specific channels, etc.
      # {
      #   "operator": "AND",
      #   "groups": [
      #     {
      #       "operator": "OR",
      #       "conditions": [
      #         { "attribute": "priority", "operator": "equals", "value": "urgent" }
      #       ]
      #     }
      #   ]
      # }
      t.jsonb :conditions,      null: false, default: {}

      # --- Configurations (catch-all JSONB for future extensibility) ---
      # e.g., "fallback_strategy": "round_robin", "skill_match_mode": "all" | "any"
      t.jsonb :configurations,  null: false, default: {}

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      # Primary lookup: fetch active policies in execution order
      t.index [:account_id, :status, :position], name: "idx_ap_execution_order"
      t.index [:account_id, :name]
      t.index [:account_id, :created_at]
    end
  end
end
