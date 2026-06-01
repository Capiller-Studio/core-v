# frozen_string_literal: true

# == Schema Information
#
# Table name: skills
#
#  id          :uuid             not null, primary key
#  description :text
#  name        :string           not null
#  skill_type  :integer          default("general"), not null
#  status      :integer          default("active"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :uuid             not null
#
# Indexes
#
#  index_skills_on_account_id                (account_id)
#  index_skills_on_account_id_and_name       (account_id,name) UNIQUE
#  index_skills_on_account_id_and_skill_type (account_id,skill_type)
#
class Skill < ShardRecord
  belongs_to :account

  has_many :user_skills, dependent: :destroy
  has_many :users, through: :user_skills, disable_joins: true

  enum :skill_type, { general: 0, language: 1, product: 2, technical: 3 }
  enum :status, { active: 0, inactive: 1 }

  validates :name, presence: true, length: { maximum: 255 },
                   uniqueness: { scope: :account_id }

  # --- Scopes ---

  scope :by_type, ->(type) { where(skill_type: type) }
  scope :ordered, -> { order(:skill_type, :name) }
end
