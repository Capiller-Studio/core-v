# frozen_string_literal: true

FactoryBot.define do
  factory :identity_source do
    account
    name { "Clearbit API #{SecureRandom.hex(4)}" }
    source_type { :api }
    source_url { "https://api.example.com/lookup" }
    headers { {} }
    params { {} }
    response_mapping { {} }
    configurations { {} }
  end
end
