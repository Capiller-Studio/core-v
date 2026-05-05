# frozen_string_literal: true

# == Schema Information
#
# Table name: automation_executions
#
#  id                    :uuid             not null, primary key
#  error_message         :text
#  executed_actions      :jsonb            not null
#  executed_at           :datetime         not null
#  execution_duration_ms :integer
#  resource_type         :string           not null
#  resource_id           :uuid             not null
#  status                :integer          default("success"), not null
#  triggered_by          :integer          default("event"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :uuid             not null
#  automation_id         :uuid             not null
#
# Indexes
#
#  idx_automation_executions_timeline                          (automation_id,executed_at)
#  index_automation_executions_on_account_id                   (account_id)
#  index_automation_executions_on_account_id_and_executed_at   (account_id,executed_at)
#  index_automation_executions_on_account_id_and_status        (account_id,status)
#  index_automation_executions_on_account_id_and_triggered_by  (account_id,triggered_by)
#  index_automation_executions_on_automation_id                (automation_id)
#  index_automation_executions_on_resource                     (resource_type,resource_id)
#
# Foreign Keys
#
#  fk_rails_...  (automation_id => automations.id) ON DELETE => cascade
#
class AutomationExecution < ShardRecord
  belongs_to :automation
  belongs_to :account
  belongs_to :resource, polymorphic: true

  enum :status, { success: 0, failed: 1, skipped: 2 }

  # triggered_by tracks HOW this execution was initiated:
  #   event (0)    — fired by a real-time event (conversation.created, message.created, etc.)
  #   schedule (1) — fired by the hourly time_trigger cron job
  #   manual (2)   — fired by an agent clicking "Run Macro" in the dashboard
  enum :triggered_by, { event: 0, schedule: 1, manual: 2 }

  validates :executed_at, presence: true

  scope :recent, -> { order(executed_at: :desc) }
  scope :failures, -> { where(status: :failed) }

  # executed_actions jsonb structure:
  # [
  #   { "action": "assign_agent", "params": { "agent_id": "..." }, "result": "success" },
  #   { "action": "set_priority", "params": { "priority": "urgent" }, "result": "success" },
  #   { "action": "send_email_to_customer", "params": { ... }, "result": "failed", "error": "Template not found" }
  # ]
  # Each entry mirrors the automation's actions array but includes the execution result.
  # This snapshot is immutable — even if the automation rule is later edited,
  # the execution log preserves exactly what ran at that point in time.
end
