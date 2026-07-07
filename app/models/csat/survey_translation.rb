# == Schema Information
#
# Table name: csat_survey_translations
#
#  id                    :integer          not null, primary key
#  csat_survey_id        :uuid             not null
#  locale                :string           not null
#  prompt                :string
#  portal_title          :string
#  portal_subtitle       :text
#  portal_feedback_label :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_csat_survey_translations_on_csat_survey_id  (csat_survey_id)
#  index_csat_survey_translations_on_locale          (locale)
#  index_csat_translations_on_survey_and_locale      (csat_survey_id,locale) UNIQUE
#

# frozen_string_literal: true

module Csat
  class SurveyTranslation < ShardRecord
    self.table_name = "csat_survey_translations"

    belongs_to :survey, class_name: "Csat::Survey"

    validates :locale, presence: true, uniqueness: { scope: :survey_id }
  end
end
