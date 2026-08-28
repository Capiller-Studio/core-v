# frozen_string_literal: true

FactoryBot.define do
  factory :integration do
    account
    provider { :slack }
    status { :active }
    settings { {} }
    credentials { {} }
    metadata { {} }
  end
end
