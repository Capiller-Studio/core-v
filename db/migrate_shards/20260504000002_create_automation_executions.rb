class CreateAutomationExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :automation_executions, id: :uuid do |t|
      # Which rule fired
      t.references :automation, null: false, type: :uuid,
                   foreign_key: { to_table: :automations, on_delete: :cascade }, index: true

      # What entity the rule acted on (Conversation, Customer, etc.)
      t.string :resource_type, null: false
      t.uuid   :resource_id,   null: false

      # status: success (0) — all actions completed, failed (1) — one or more actions errored,
      #         skipped (2) — conditions didn't match (logged for debugging)
      t.integer :status, null: false, default: 0

      # triggered_by: event (0) — real-time event trigger, schedule (1) — hourly cron,
      #               manual (2) — agent clicked "Run Macro"
      t.integer :triggered_by, null: false, default: 0

      # executed_actions jsonb — snapshot of what actually ran and each action's outcome:
      # [
      #   { "action": "assign_agent", "params": { "agent_id": "..." }, "result": "success" },
      #   { "action": "set_priority", "params": { "priority": "urgent" }, "result": "success" },
      #   { "action": "send_email_to_customer", "params": { ... }, "result": "failed", "error": "Template not found" }
      # ]
      t.jsonb :executed_actions, null: false, default: []

      t.text    :error_message            # Summary error if status == failed
      t.integer :execution_duration_ms    # How long the full execution took (for performance monitoring)
      t.datetime :executed_at, null: false # When the execution happened (distinct from created_at for queued jobs)

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      t.index [:resource_type, :resource_id]
      t.index [:account_id, :status]
      t.index [:account_id, :triggered_by]
      t.index [:account_id, :executed_at]
      # Fast lookup: "show me all executions for this automation rule, most recent first"
      t.index [:automation_id, :executed_at], name: "idx_automation_executions_timeline"
    end
  end
end
