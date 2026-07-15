FactoryBot.define do
  factory :skill do
    account
    name { "Skill #{SecureRandom.hex(4)}" }
    skill_type { :general }
    status { :active }
  end
end
