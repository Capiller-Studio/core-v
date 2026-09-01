# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id              :uuid             not null, primary key
#  configurations  :jsonb            not null
#  description     :text
#  flags           :integer          default(0), not null
#  identifier      :string           not null
#  name            :string           not null
#  status          :integer          default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
# Indexes
#
#  index_teams_on_account_id                 (account_id)
#  index_teams_on_account_id_and_created_at  (account_id,created_at)
#  index_teams_on_account_id_and_flags       (account_id,flags)
#  index_teams_on_account_id_and_identifier  (account_id,identifier) UNIQUE
#  index_teams_on_account_id_and_name        (account_id,name)
#  index_teams_on_account_id_and_status      (account_id,status)
#
class Team < ShardRecord
  include FlagShihTzu
  include SlugGenerator.new(source: :name, column: :identifier, scope: :account_id)
  include Avatarable
  include UsageTrackable
  include Trackable

  has_flags 1 => :auto_assign, column: 'flags'

  belongs_to :account

  has_many :team_users, dependent: :destroy
  has_many :users, through: :team_users, disable_joins: true

  has_many :inbox_teams, dependent: :destroy
  has_many :inboxes, through: :inbox_teams

  has_many :conversations, dependent: :nullify
  has_many :macros, as: :scopeable, dependent: :nullify, class_name: "Macro"

  enum :status, { active: 0, inactive: 1, archived: 2 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :identifier, presence: true, uniqueness: { scope: :account_id }
  validate :validate_configurations

  tracks_usage :teams

  # --- Scopes ---

  scope :with_members, -> { joins(:team_users).distinct }
  scope :by_account, ->(account) { where(account: account) }

  # --- Instance Methods ---

  # Returns the first lead user, or nil
  def lead
    team_users.lead.first&.user
  end

  # Returns all lead users
  def leads
    User.where(id: team_users.lead.pluck(:user_id))
  end

  # Returns all non-lead members
  def members
    User.where(id: team_users.member.pluck(:user_id))
  end

  def member?(user)
    team_users.exists?(user_id: user.id)
  end

  def online_members
    User.where(id: team_users.pluck(:user_id)).where(
      id: AccountUser.where(account_id: account_id, availability: :online).select(:user_id)
    )
  end

  # Payload for ActionCable/event broadcasting
  def event_payload
    {
      id:,
      name:,
      identifier:,
      status:,
      auto_assign:,
      description:,
      member_count: team_users.size,
      created_at:,
      updated_at:
    }
  end

  # --- Configurations ---
  #
  # The configurations JSONB stores team-level settings:
  #   {
  #     "assignment_policy": "round_robin" | "load_balanced" | "manual",
  #     "max_conversations_per_agent": 20,
  #     "auto_reassign_on_offline": true
  #   }
  #
  # These will be consumed by a future AssignmentPolicy service.

  def assignment_policy
    configurations.fetch("assignment_policy", "round_robin")
  end

  def max_conversations_per_agent
    configurations.fetch("max_conversations_per_agent", nil)
  end

  def auto_reassign_on_offline?
    configurations.fetch("auto_reassign_on_offline", false)
  end

  private

  def validate_configurations
    errors.add(:configurations, "must be a hash") unless configurations.is_a?(Hash)
  end
end
