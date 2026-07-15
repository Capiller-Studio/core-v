FactoryBot.define do
  factory :business_hour_group do
    account
    name { "Group #{SecureRandom.hex(4)}" }
  end
end
