# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

# Shared concern for models that execute an ordered list of actions.
# Currently used by Automation (automatic rules) and Macro (manual one-click actions).
#
# Provides:
#   - actions JSONB validation via ActionsValidator
#   - Polymorphic association to AutomationExecution for logging
#   - toggle! and duplicate helpers
#
# Usage:
#   class Automation < ShardRecord
#     include Actionable
#   end
module Actionable
  extend ActiveSupport::Concern

  included do
    has_many :executions, as: :executable, class_name: "AutomationExecution", dependent: :destroy

    validate :validate_actions_jsonb

    enum :status, { active: 0, inactive: 1 }
  end

  def toggle!
    active? ? inactive! : active!
  end

  # actions jsonb structure:
  # [
  #   { "action": "assign_agent",   "params": { "agent_id": "uuid" } },
  #   { "action": "set_priority",   "params": { "priority": "urgent" } },
  #   { "action": "add_label",      "params": { "label_ids": ["uuid-1"] } },
  #   { "action": "send_message",   "params": { "content": "...", "visibility": "global" } }
  # ]
  #
  # Full Action Catalog:
  #   assign_agent, assign_team, unassign, set_status, set_priority,
  #   add_label, remove_label, set_custom_field, send_message,
  #   send_email_to_customer, send_email_to_team, add_note,
  #   snooze, resolve, mute_conversation, trigger_webhook, set_locale

  private

  def validate_actions_jsonb
    return if actions.blank?

    validator = Automations::ActionsValidator.new(actions: actions)
    validator.call.each { |msg| errors.add(:base, msg) }
  end
end
