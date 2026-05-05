FactoryBot.define do
  factory :conversation_member do
    account { conversation.account }
    conversation
    association :member, factory: :customer
  end
end
