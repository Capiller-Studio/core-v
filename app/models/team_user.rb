# frozen_string_literal: true

# == Schema Information
#
# Table name: team_users
#
#  id         :uuid             not null, primary key
#  role       :integer          default("member"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_team_users_on_created_at           (created_at)
#  index_team_users_on_team_id              (team_id)
#  index_team_users_on_team_id_and_user_id  (team_id,user_id) UNIQUE
#  index_team_users_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id) ON DELETE => cascade
#
class TeamUser < ShardRecord
  belongs_to :team
  belongs_to :user

  enum :role, { member: 0, lead: 1 }

  validates :user_id, uniqueness: { scope: :team_id }
  validate :user_belongs_to_team_account

  private

  # Ensure the user actually belongs to the same account as the team.
  # User <-> Account relationship is through AccountUser in the primary DB,
  # so we check AccountUser existence.
  def user_belongs_to_team_account
    return if team.blank? || user.blank?

    unless AccountUser.exists?(account_id: team.account_id, user_id: user_id)
      errors.add(:user, :invalid)
    end
  end
end
