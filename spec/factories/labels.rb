FactoryBot.define do
  factory :label do
    account
    title { FFaker::Lorem.word }
    sequence(:identifier) { |n| "LABEL#{n}_#{SecureRandom.hex(4)}" }
    color { '#2D89EF' }
    configurations { {} }
  end
end
