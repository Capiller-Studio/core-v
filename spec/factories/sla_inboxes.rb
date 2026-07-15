FactoryBot.define do
  factory :sla_inbox do
    account
    sla_policy
    inbox
  end
end
