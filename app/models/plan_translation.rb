# frozen_string_literal: true

class PlanTranslation < ApplicationRecord
  belongs_to :plan

  validates :locale, presence: true, uniqueness: { scope: :plan_id }
  validates :display_name, presence: true
end
