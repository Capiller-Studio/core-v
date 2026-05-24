FactoryBot.define do
  factory :plan do
    name { Plan::ANABOLIC }
    display_name { 'Starter Plan' }
    description { 'Everything you need to get started.' }
    base_price { 0 }
    annual_price { 0 }
    configurations { {} }
    limits { {} }
    status { :active }

    trait :momentum do
      name { Plan::HYPERBOLIC }
      display_name { 'Momentum Plan' }
      base_price { 49 }
      annual_price { 490 }
    end

    trait :kinetic do
      name { Plan::KINETIC }
      display_name { 'Kinetic Plan' }
      base_price { 99 }
      annual_price { 990 }
    end

    trait :supernova do
      name { Plan::SUPERNOVA }
      display_name { 'Supernova Plan' }
      base_price { 299 }
      annual_price { 2990 }
    end
  end
end
