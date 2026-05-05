class CreateAutomations < ActiveRecord::Migration[7.1]
  def change
    create_table :automations, id: :uuid do |t|
      t.string  :name, null: false
      t.text    :description

      # automation_type determines trigger mechanism:
      #   macro (0)         — manually triggered by an agent clicking "Run" on a conversation
      #   event_trigger (1) — fires instantly when a matching event occurs (e.g., conversation.created)
      #   time_trigger (2)  — evaluated hourly by a scheduled cron job (e.g., hours since last activity)
      t.integer :automation_type, null: false, default: 0

      # event_name: which event activates this rule.
      # For event_trigger: "conversation.created", "message.created", etc. (see Event Catalog)
      # For time_trigger:  "hours_since_created", "hours_since_updated", etc.
      # For macro:         NULL (triggered manually)
      #
      # Full Event Catalog:
      #   conversation.created, conversation.updated, conversation.status_changed,
      #   conversation.assigned, conversation.resolved,
      #   message.created, message.incoming, message.outgoing,
      #   customer.created, customer.updated,
      #   sla.breached,
      #   hours_since_created, hours_since_updated, hours_since_resolved, hours_since_last_activity
      t.string :event_name

      # conditions jsonb — nested AND/OR condition groups:
      # {
      #   "operator": "AND",                      (top-level: combine groups with AND or OR)
      #   "groups": [
      #     {
      #       "operator": "OR",                   (within group: combine conditions with AND or OR)
      #       "conditions": [
      #         {
      #           "attribute": "status",           (what to check — see Supported Attributes below)
      #           "operator": "equals",            (comparison — see Supported Operators below)
      #           "value": "active"                (target value)
      #         }
      #       ]
      #     }
      #   ]
      # }
      #
      # Supported Operators:
      #   equals, not_equals, contains, not_contains, starts_with, ends_with,
      #   is_present, is_not_present, greater_than, less_than, days_before
      #
      # Supported Attributes:
      #   Conversation: status, priority, source, locale, title, identifier
      #   Inbox:        inbox.id, inbox.name, inbox.channel_type
      #   Assignee:     assignee.id, assignee.name, assignee.email
      #   Team:         team.id, team.name
      #   Customer:     customer.email, customer.name, customer.locale, customer.customer_type
      #   Message:      message.content, message.content_type, message.sender_type
      #   Labels:       labels (array contains check)
      #   Custom Fields: custom_field.<key> (reads from entity's data jsonb)
      #   Time:         hours_since_created, hours_since_updated, hours_since_resolved, hours_since_last_activity
      t.jsonb :conditions, null: false, default: {}

      # actions jsonb — ordered array of actions to execute sequentially:
      # [
      #   {
      #     "action": "assign_agent",              (action identifier — see Action Catalog)
      #     "params": { "agent_id": "uuid" }       (action-specific parameters)
      #   }
      # ]
      #
      # Action Catalog:
      #   assign_agent        { agent_id }
      #   assign_team         { team_id }
      #   unassign            {}
      #   set_status          { status }            (active, closed, snoozed, resolved)
      #   set_priority        { priority }          (low, medium, high, urgent)
      #   add_label           { label_ids }
      #   remove_label        { label_ids }
      #   set_custom_field    { key, value }        (writes to entity's data jsonb)
      #   send_message        { content, visibility } (sends as system/bot)
      #   send_email_to_customer { email_template_id }
      #   send_email_to_team  { email_template_id, team_id }
      #   add_note            { content }           (internal note on conversation)
      #   snooze              { duration_hours }
      #   resolve             {}
      #   mute_conversation   {}
      #   trigger_webhook     { url, method, headers }
      #   set_locale          { locale }
      t.jsonb :actions, null: false, default: []

      t.integer :position   # Processing order within automation_type (lower = first). NULL for macros.
      t.integer :status,    null: false, default: 0
      t.integer :flags,     null: false, default: 0
      # flags (FlagShihTzu bit fields):
      #   1 => :stop_processing — if this rule fires, skip all lower-priority rules for this event

      # is_system: true for platform-provided automations (e.g., auto-close after 48h).
      # Users can toggle on/off but cannot delete system automations.
      # Naming matches AccessRole.is_system for consistency.
      t.boolean :is_system, null: false, default: false

      # configurations jsonb — type-specific settings (currently for time_trigger scheduling):
      # {
      #   "interval_hours" => 1,    (how often to evaluate — default hourly, matching Zendesk/Freshdesk)
      #   "max_cascade_depth" => 3  (max cascading trigger depth to prevent infinite loops)
      # }
      t.jsonb :configurations, null: false, default: {}

      t.references :account, null: false, foreign_key: false, type: :uuid, index: true
      # user_id is the author. Required for macros (personal to an agent), NULL for account-level triggers.
      t.references :user, foreign_key: false, type: :uuid, index: true

      t.timestamps default: -> { "CURRENT_TIMESTAMP" }

      # Primary lookup: fetch active rules for a specific event on this account
      t.index [:account_id, :automation_type, :event_name, :status], name: "idx_automations_event_lookup"
      t.index [:account_id, :automation_type, :status, :position],   name: "idx_automations_execution_order"
      t.index [:account_id, :name]
      t.index [:account_id, :is_system]
      t.index [:account_id, :created_at]
    end
  end
end
