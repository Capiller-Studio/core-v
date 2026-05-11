class CreateAutomationExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :automation_executions, id: :uuid do |t|
      # Polymorphic: which rule/macro fired (Automation or Macro)
      t.references :executable, polymorphic: true, null: false, type: :uuid

      # What entity the rule acted on (Conversation, Customer, etc.)
      t.references :resource, polymorphic: true, null: false, type: :uuid

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

      t.index [:executable_type, :executable_id, :executed_at], name: "idx_automation_executions_executable_timeline"
      t.index [:account_id, :status]
      t.index [:account_id, :triggered_by]
      t.index [:account_id, :executed_at]
    end
  end
end
