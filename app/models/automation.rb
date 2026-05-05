# frozen_string_literal: true

# == Schema Information
#
# Table name: automations
#
#  id               :uuid             not null, primary key
#  actions          :jsonb            not null
#  automation_type  :integer          default("macro"), not null
#  conditions       :jsonb            not null
#  configurations   :jsonb            not null
#  description      :text
#  event_name       :string
#  flags            :integer          default(0), not null
#  is_system        :boolean          default(FALSE), not null
#  name             :string           not null
#  position         :integer
#  status           :integer          default("active"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#  user_id          :uuid
#
# Indexes
#
#  idx_automations_event_lookup      (account_id,automation_type,event_name,status)
#  idx_automations_execution_order   (account_id,automation_type,status,position)
#  index_automations_on_account_id                 (account_id)
#  index_automations_on_account_id_and_created_at  (account_id,created_at)
#  index_automations_on_account_id_and_is_system   (account_id,is_system)
#  index_automations_on_account_id_and_name        (account_id,name)
#  index_automations_on_user_id                    (user_id)
#
class Automation < ShardRecord
  include FlagShihTzu

  belongs_to :account
  # Macros have an author (the agent who created them); event/time triggers are account-level (user is nil).
  belongs_to :user, optional: true

  has_many :executions, class_name: "AutomationExecution", dependent: :destroy

  enum :automation_type, { macro: 0, event_trigger: 1, time_trigger: 2 }
  enum :status, { active: 0, inactive: 1 }

  # stop_processing: if this rule fires, skip all subsequent rules in the execution chain.
  # Mimics Zendesk's "stop processing subsequent triggers" behaviour.
  # Useful for catch-all rules that should be the final handler.
  has_flags 1 => :stop_processing,
            column: "flags"

  validates :name, presence: true
  validates :event_name, presence: true, if: -> { event_trigger? || time_trigger? }
  validates :user_id, presence: true, if: :macro?

  # Scopes for the three execution paths
  scope :event_triggers_for, ->(event_name) {
    where(automation_type: :event_trigger, event_name: event_name, status: :active).order(:position)
  }
  scope :time_triggers, -> {
    where(automation_type: :time_trigger, status: :active).order(:position)
  }
  scope :macros_for_user, ->(user) {
    where(automation_type: :macro, status: :active, user: user).or(
      where(automation_type: :macro, status: :active, is_system: true)
    )
  }

  # conditions jsonb structure:
  # {
  #   "operator": "AND",
  #   "groups": [
  #     {
  #       "operator": "OR",
  #       "conditions": [
  #         { "attribute": "status", "operator": "equals", "value": "active" },
  #         { "attribute": "status", "operator": "equals", "value": "snoozed" }
  #       ]
  #     },
  #     {
  #       "operator": "AND",
  #       "conditions": [
  #         { "attribute": "priority", "operator": "equals", "value": "urgent" },
  #         { "attribute": "inbox.name", "operator": "contains", "value": "VIP" }
  #       ]
  #     }
  #   ]
  # }
  #
  # Supported operators:
  #   equals, not_equals, contains, not_contains, starts_with, ends_with,
  #   is_present, is_not_present, greater_than, less_than, days_before
  #
  # Supported attributes:
  #   Conversation: status, priority, source, locale, title, identifier
  #   Inbox:        inbox.id, inbox.name, inbox.channel_type
  #   Assignee:     assignee.id, assignee.name, assignee.email
  #   Team:         team.id, team.name
  #   Customer:     customer.email, customer.name, customer.locale, customer.customer_type
  #   Message:      message.content, message.content_type, message.sender_type
  #   Labels:       labels (array contains)
  #   Custom Fields: custom_field.<key> (reads from entity's data jsonb)
  #   Time:         hours_since_created, hours_since_updated, hours_since_resolved, hours_since_last_activity

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

  # configurations jsonb structure (mainly for time_trigger scheduling):
  # {
  #   "interval_hours"    => 1,    (evaluation interval — default hourly, matching Zendesk/Freshdesk)
  #   "max_cascade_depth" => 3     (max depth for cascading trigger execution to prevent infinite loops)
  # }
end
