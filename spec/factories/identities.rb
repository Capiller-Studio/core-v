# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    account
    customer
    association :identity_source, factory: :identity_source
    identity_type { :custom_api }
    identifier { SecureRandom.uuid }
    custom_attributes { {} }
    configurations { {} }
    raw_response { {} }
  end
end
