FactoryBot.define do
  factory :plan do
    name { Plan::STARTER }
    display_name { 'Starter Plan' }
    description { 'Everything you need to get started.' }
    base_price { 0 }
    annual_price { 0 }
    configurations { {} }
    limits { {} }
    status { :active }

    trait :momentum do
      name { Plan::MOMENTUM }
      display_name { 'Momentum Plan' }
      base_price { 49 }
      annual_price { 490 }
    end

    trait :pinnacle do
      name { Plan::PINNACLE }
      display_name { 'Pinnacle Plan' }
      base_price { 99 }
      annual_price { 990 }
    end

    trait :enterprise do
      name { Plan::ENTERPRISE }
      display_name { 'Enterprise Plan' }
      base_price { 299 }
      annual_price { 2990 }
    end
  end
end
