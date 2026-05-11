# frozen_string_literal: true

# == Schema Information
#
# Table name: automations
#
#  id               :uuid             not null, primary key
#  actions          :jsonb            not null
#  automation_type  :integer          default("event_trigger"), not null
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
#
# Indexes
#
#  idx_automations_event_lookup      (account_id,automation_type,event_name,status)
#  idx_automations_execution_order   (account_id,automation_type,status,position)
#  index_automations_on_account_id                 (account_id)
#  index_automations_on_account_id_and_created_at  (account_id,created_at)
#  index_automations_on_account_id_and_is_system   (account_id,is_system)
#  index_automations_on_account_id_and_name        (account_id,name)
#
class Automation < ShardRecord
  include Actionable
  include FlagShihTzu

  belongs_to :account

  enum :automation_type, { event_trigger: 1, time_trigger: 2 }

  # stop_processing: if this rule fires, skip all subsequent rules in the execution chain.
  # Mimics Zendesk's "stop processing subsequent triggers" behaviour.
  # Useful for catch-all rules that should be the final handler.
  has_flags 1 => :stop_processing,
            column: "flags"

  validates :name, presence: true
  validates :event_name, presence: true
  validate :validate_conditions_jsonb

  before_create :assign_next_position

  # --- Scopes ---

  scope :event_triggers_for, ->(event_name) {
    where(automation_type: :event_trigger, event_name: event_name, status: :active).order(:position)
  }
  scope :time_triggers, -> {
    where(automation_type: :time_trigger, status: :active).order(:position)
  }

  # --- Instance Methods ---

  def duplicate(new_name: nil)
    dup.tap do |copy|
      copy.name = new_name || "#{name} (copy)"
      copy.status = :inactive
      copy.is_system = false
      copy.position = nil # Will be auto-assigned by before_create
    end
  end

  # --- Custom Position Management ---

  # Reorder automations by an ordered list of IDs.
  # Updates positions in a single UPDATE statement for performance.
  def self.reorder!(ordered_ids)
    return if ordered_ids.blank?

    transaction do
      ordered_ids.each_with_index do |id, index|
        where(id: id).update_all(position: index + 1) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

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

  # configurations jsonb structure (mainly for time_trigger scheduling):
  # {
  #   "interval_hours"    => 1,    (evaluation interval — default hourly, matching Zendesk/Freshdesk)
  #   "max_cascade_depth" => 3     (max depth for cascading trigger execution to prevent infinite loops)
  # }

  private

  def validate_conditions_jsonb
    return if conditions.blank?

    validator = Automations::AutomationValidator.new(conditions: conditions)
    validator.call.each { |msg| errors.add(:base, msg) }
  end

  def assign_next_position
    return if position.present?

    max_pos = account.automations
                     .where(automation_type: automation_type)
                     .maximum(:position) || 0
    self.position = max_pos + 1
  end
end
