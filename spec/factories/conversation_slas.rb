FactoryBot.define do
  factory :conversation_sla do
    account
    conversation
    sla_policy
    status { :pending }
  end
end
