FactoryBot.define do
  factory :canned_response do
    account
    name { FFaker::Lorem.sentence }
    sequence(:identifier) { |n| "CR#{n}_#{SecureRandom.hex(4)}" }
    status { :active }
  end
end
