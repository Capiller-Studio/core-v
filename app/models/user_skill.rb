# frozen_string_literal: true

# == Schema Information
#
# Table name: user_skills
#
#  id          :uuid             not null, primary key
#  proficiency :integer          default("beginner"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#  skill_id    :uuid             not null
#  user_id     :uuid             not null
#
# Indexes
#
#  idx_user_skill_unique                    (user_id,skill_id) UNIQUE
#  index_user_skills_on_account_id          (account_id)
#  index_user_skills_on_skill_id            (skill_id)
#
# Foreign Keys
#
#  fk_rails_...  (skill_id => skills.id) ON DELETE => cascade
#
class UserSkill < ShardRecord
  belongs_to :skill
  belongs_to :user
  belongs_to :account

  enum :proficiency, { beginner: 1, intermediate: 2, expert: 3 }

  validates :user_id, uniqueness: { scope: :skill_id }
  validates :proficiency, presence: true
  validate :user_belongs_to_account

  # --- Scopes ---

  scope :for_user, ->(user) { where(user: user) }
  scope :for_skill, ->(skill) { where(skill: skill) }
  scope :with_min_proficiency, ->(level) { where("proficiency >= ?", proficiencies[level]) }

  private

  # Ensure the user actually belongs to the same account as the skill.
  # User <-> Account relationship is through AccountUser in the primary DB.
  def user_belongs_to_account
    return if account.blank? || user.blank?

    unless AccountUser.exists?(account_id: account_id, user_id: user_id)
      errors.add(:user, :invalid)
    end
  end
end
