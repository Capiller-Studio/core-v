FactoryBot.define do
  factory :customer do
    account
    address
    name { FFaker::Name.name }
    sequence(:email) { |n| "customer_#{n}_#{SecureRandom.hex(4)}@example.com" }
    status { :active }
    customer_type { :customer }
    configurations { {} }
    data { {} }
    tokens { {} }
    schedular_data { {} }
  end
end
