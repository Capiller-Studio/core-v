FactoryBot.define do
  factory :message do
    account
    conversation
    inbox { conversation.inbox }
    sender { association :customer, account: account }
    content { FFaker::Lorem.sentence }
    content_type { :text }
    status { :sent }
    visibility { :global }
    data { {} }
    sentiment { {} }
    configurations { {} }
    
    trait :outgoing do
      sender { association :user }
    end
  end
end
