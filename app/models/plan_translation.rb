# == Schema Information
#
# Table name: plan_translations
#
#  id           :uuid             not null, primary key
#  locale       :string           not null
#  display_name :string           not null
#  description  :text
#  plan_id      :uuid             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_plan_translations_on_plan_id             (plan_id)
#  index_plan_translations_on_plan_id_and_locale  (plan_id,locale) UNIQUE
#

# frozen_string_literal: true

class PlanTranslation < ApplicationRecord
  belongs_to :plan

  validates :locale, presence: true, uniqueness: { scope: :plan_id }
  validates :display_name, presence: true
end
