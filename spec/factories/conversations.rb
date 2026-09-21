FactoryBot.define do
  factory :conversation do
    account
    inbox
    sequence(:identifier) { |n| "CONV#{n}_#{SecureRandom.hex(4)}".upcase }
    status { :active }
    priority { :low }
    configurations { {} }
    data { {} }
  end
end
