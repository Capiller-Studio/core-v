FactoryBot.define do
  factory :account do
    name { FFaker::Company.name }
    sequence(:identifier) { |n| "acc-#{n}-#{SecureRandom.hex(4)}" }
    sequence(:referral_code) { |n| "REF#{n}#{SecureRandom.hex(2)}" }
    billing_data { {} }
    configurations { {} }
    data { {} }
    limits { {} }
    locale { "en" }
    currency { "USD" }
    status { :active }

    trait :with_features do
      teams_enabled { true }
      automations_enabled { true }
    end
  end
end
