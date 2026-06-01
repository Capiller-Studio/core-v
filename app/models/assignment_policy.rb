# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_policies
#
#  id                                   :uuid             not null, primary key
#  conditions                           :jsonb            not null
#  configurations                       :jsonb            not null
#  description                          :text
#  flags                                :integer          default(0), not null
#  idle_timeout_minutes                 :integer
#  max_conversations_per_agent          :integer
#  name                                 :string           not null
#  position                             :integer
#  prioritize_by_conversation_priority  :boolean          default(FALSE), not null
#  reassign_on_offline                  :boolean          default(FALSE), not null
#  respect_business_hours               :boolean          default(FALSE), not null
#  status                               :integer          default("active"), not null
#  strategy                             :integer          default("round_robin"), not null
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  account_id                           :uuid             not null
#  business_hour_group_id               :uuid
#
# Indexes
#
#  idx_ap_execution_order                                (account_id,status,position)
#  index_assignment_policies_on_account_id               (account_id)
#  index_assignment_policies_on_account_id_and_created_at (account_id,created_at)
#  index_assignment_policies_on_account_id_and_name      (account_id,name)
#  index_assignment_policies_on_business_hour_group_id   (business_hour_group_id)
#
# Foreign Keys
#
#  fk_rails_...  (business_hour_group_id => business_hour_groups.id) ON DELETE => nullify
#
class AssignmentPolicy < ShardRecord
  include FlagShihTzu

  belongs_to :account
  belongs_to :business_hour_group, optional: true

  has_many :assignment_policy_inboxes, dependent: :destroy
  has_many :inboxes, through: :assignment_policy_inboxes

  # --- Strategy ---
  # Determines the algorithm used to select an agent:
  #   round_robin   — rotate evenly across eligible agents (like Zendesk/Freshdesk)
  #   load_balanced — assign to agent with fewest open conversations (like Intercom Balanced)
  #   skills_based  — match required skills, then load-balance among matching agents
  #   manual        — no auto-assign; agents pick from queue
  enum :strategy, { round_robin: 0, load_balanced: 1, skills_based: 2, manual: 3 }

  enum :status, { active: 0, inactive: 1 }

  # --- Flags (FlagShihTzu bit fields) ---
  has_flags 1 => :consider_agent_skills,
            2 => :allow_idle_reassignment,
            3 => :notify_on_assignment,
            4 => :notify_team_leads,
            column: "flags"

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :max_conversations_per_agent,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :idle_timeout_minutes,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :validate_conditions_jsonb
  validate :validate_business_hours_presence

  before_create :assign_next_position

  # --- Scopes ---

  scope :ordered, -> { order(:position) }

  # Find the first active policy that applies to a given inbox
  scope :for_inbox, ->(inbox) {
    joins(:assignment_policy_inboxes)
      .where(assignment_policy_inboxes: { inbox_id: inbox.id })
      .active.ordered
  }

  # --- Instance Methods ---

  def toggle!
    active? ? inactive! : active!
  end

  def within_business_hours?(time: Time.current)
    return true unless respect_business_hours? && business_hour_group.present?

    AssignmentPolicies::BusinessHoursChecker.call(
      business_hour_group: business_hour_group,
      time: time
    )
  end

  # conditions jsonb structure (identical to Automation#conditions):
  # {
  #   "operator": "AND",
  #   "groups": [
  #     {
  #       "operator": "OR",
  #       "conditions": [
  #         { "attribute": "priority", "operator": "equals", "value": "urgent" },
  #         { "attribute": "inbox.channel_type", "operator": "equals", "value": "Channel::Email" }
  #       ]
  #     }
  #   ]
  # }

  # configurations jsonb structure:
  # {
  #   "skill_match_mode": "all" | "any",        — require ALL or ANY skills to match
  #   "fallback_strategy": "round_robin",        — fallback if no agent matches skills
  #   "required_skill_ids": ["uuid-1", "uuid-2"] — skills required for skills_based strategy
  # }

  private

  def validate_conditions_jsonb
    return if conditions.blank? || conditions == {}

    validator = Automations::AutomationValidator.new(conditions: conditions)
    validator.call.each { |msg| errors.add(:base, msg) }
  end

  def validate_business_hours_presence
    if respect_business_hours? && business_hour_group_id.blank?
      errors.add(:business_hour_group, :required_with_business_hours)
    end
  end

  def assign_next_position
    return if position.present?

    max_pos = account.assignment_policies.maximum(:position) || 0
    self.position = max_pos + 1
  end
end
