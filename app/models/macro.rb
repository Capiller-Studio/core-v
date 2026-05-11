# frozen_string_literal: true

# == Schema Information
#
# Table name: macros
#
#  id              :uuid             not null, primary key
#  actions         :jsonb            not null
#  description     :text
#  flags           :integer          default(0), not null
#  is_system       :boolean          default(FALSE), not null
#  name            :string           not null
#  scopeable_type  :string
#  scopeable_id    :uuid
#  status          :integer          default("active"), not null
#  visibility      :integer          default("account_wide"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
class Macro < ShardRecord
  include Actionable
  include FlagShihTzu

  belongs_to :account
  belongs_to :scopeable, polymorphic: true, optional: true

  has_flags column: "flags"

  enum :visibility, { account_wide: 0, personal: 1, team: 2 }

  validates :name, presence: true
  validate :scopeable_matches_visibility

  # --- Scopes ---

  # All macros accessible by a given user:
  #   1. Account-wide (visible to everyone)
  #   2. Personal (owned by this user)
  #   3. Team (user is a member of one of these teams)
  #   4. System macros
  scope :for_user, ->(user, team_ids: []) {
    account_wide_or_system = where(visibility: :account_wide)
                               .or(where(is_system: true))

    personal = where(visibility: :personal, scopeable_type: "User", scopeable_id: user.id)

    if team_ids.present?
      team_scoped = where(visibility: :team, scopeable_type: "Team", scopeable_id: team_ids)
      account_wide_or_system.or(personal).or(team_scoped)
    else
      account_wide_or_system.or(personal)
    end
  }

  scope :account_wide_macros, -> { where(visibility: :account_wide, is_system: false) }
  scope :personal_macros, ->(user) { where(visibility: :personal, scopeable_type: "User", scopeable_id: user.id) }
  scope :team_macros, ->(team) { where(visibility: :team, scopeable_type: "Team", scopeable_id: team.id) }
  scope :system_macros, -> { where(is_system: true) }

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

  def duplicate(new_name: nil)
    dup.tap do |copy|
      copy.name = new_name || "#{name} (copy)"
      copy.status = :inactive
      copy.is_system = false
    end
  end

  private

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
