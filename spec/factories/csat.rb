# frozen_string_literal: true

FactoryBot.define do
  factory :csat_survey, class: 'Csat::Survey' do
    account
    name { "CSAT Survey #{SecureRandom.hex(4)}" }
    prompt { "How would you rate our support?" }
  end

  factory :csat_survey_response, class: 'Csat::SurveyResponse' do
    account
    conversation
    customer
    association :csat_survey, factory: :csat_survey
    status { :pending }
  end
end
