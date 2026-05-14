FactoryBot.define do
  factory :team do
    account
    name { FFaker::Education.major }
    sequence(:identifier) { |n| "TEAM#{n}_#{SecureRandom.hex(4)}" }
    status { :active }
    auto_assign { true }
    configurations { { "assignment_policy" => "round_robin" } }
  end
end
