# frozen_string_literal: true

# == Schema Information
#
# Table name: macros
#
#  id              :uuid             not null, primary key
#  actions         :jsonb            not null
#  description     :text
#  flags           :integer          default(0), not null
#  name            :string           not null
#  scopeable_type  :string
#  scopeable_id    :uuid
#  status          :integer          default("active"), not null
#  system_provided :boolean          default(FALSE), not null
#  visibility      :integer          default("account_wide"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
class Macro < ShardRecord
  include Actionable
  include FlagShihTzu
  include UsageTrackable
  include Trackable

  belongs_to :account
  belongs_to :scopeable, polymorphic: true, optional: true

  has_flags column: "flags"

  enum :visibility, { account_wide: 0, personal: 1, team: 2 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 500 }
  validate :actions_present
  validate :scopeable_matches_visibility

  tracks_usage :macros

  # --- Scopes ---

  # All macros accessible by a given user:
  #   1. Account-wide (visible to everyone)
  #   2. Personal (owned by this user)
  #   3. Team (user is a member of one of these teams)
  #   4. System macros
  scope :for_user, ->(user, team_ids: []) {
    account_wide_or_system = where(visibility: :account_wide)
                               .or(where(system_provided: true))

    personal = where(visibility: :personal, scopeable_type: "User", scopeable_id: user.id)

    if team_ids.present?
      team_scoped = where(visibility: :team, scopeable_type: "Team", scopeable_id: team_ids)
      account_wide_or_system.or(personal).or(team_scoped)
    else
      account_wide_or_system.or(personal)
    end
  }

  scope :account_wide_macros, -> { where(visibility: :account_wide, system_provided: false) }
  scope :personal_macros, ->(user) { where(visibility: :personal, scopeable_type: "User", scopeable_id: user.id) }
  scope :team_macros, ->(team) { where(visibility: :team, scopeable_type: "Team", scopeable_id: team.id) }
  scope :system_macros, -> { where(system_provided: true) }
  scope :executable, -> { where(status: :active) }

  # --- Class Methods ---

  # IDs of the account's teams the given user belongs to.
  # Used to resolve team-scoped macro visibility.
  def self.team_ids_for(user, account)
    return [] unless user && account

    account.teams.joins(:team_users).where(team_users: { user_id: user.id }).distinct.pluck(:id)
  end

  # Macros the user can see/run within the account (account-wide, system, own personal, own teams).
  def self.visible_to(user, account)
    where(account: account).for_user(user, team_ids: team_ids_for(user, account))
  end

  # --- Instance Methods ---

  def owner
    personal? ? scopeable : nil
  end

  def team
    team? ? scopeable : nil
  end

  def owned_by?(user)
    personal? && scopeable_type == "User" && scopeable_id == user.id
  end

  # Whether the given user is allowed to see (and therefore run) this macro.
  def visible_to?(user, team_ids: nil)
    return false unless user
    return true if system_provided? || account_wide?
    return owned_by?(user) if personal?

    if team?
      team_ids ||= self.class.team_ids_for(user, account)
      return scopeable_type == "Team" && team_ids.include?(scopeable_id)
    end

    false
  end

  # Ordered list of action names, e.g. ["set_status", "send_message"]
  def action_names
    Array(actions).filter_map { |a| a["action"] || a[:action] }
  end

  def duplicate(new_name: nil)
    dup.tap do |copy|
      copy.name = new_name || "#{name} (copy)"
      copy.status = :inactive
      copy.system_provided = false
    end
  end

  private

  def actions_present
    errors.add(:actions, :blank) if Array(actions).empty?
  end

  def scopeable_matches_visibility
    case visibility
    when "personal"
      errors.add(:scopeable, "must be a User for personal macros") unless scopeable_type == "User" && scopeable_id.present?
    when "team"
      errors.add(:scopeable, "must be a Team for team macros") unless scopeable_type == "Team" && scopeable_id.present?
    when "account_wide"
      errors.add(:scopeable, "must be blank for account-wide macros") if scopeable_type.present? || scopeable_id.present?
    end
  end
end
