FactoryBot.define do
  factory :assignment_policy do
    account
    name { "Policy #{SecureRandom.hex(4)}" }
    status { :active }
    strategy { :round_robin }
    conditions { {} }
    configurations { {} }
  end
end
