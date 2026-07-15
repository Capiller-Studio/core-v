FactoryBot.define do
  factory :sla_policy do
    account
    name { "SLA #{SecureRandom.hex(4)}" }
    configurations { {} }
  end
end
