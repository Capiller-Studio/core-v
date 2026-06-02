# frozen_string_literal: true

module Csat
  class SurveyTranslation < ShardRecord
    self.table_name = "csat_survey_translations"

    belongs_to :csat_survey, class_name: "Csat::Survey"

    validates :locale, presence: true, uniqueness: { scope: :csat_survey_id }
  end
end
