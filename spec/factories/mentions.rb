FactoryBot.define do
  factory :mention do
    account
    association :resource, factory: :conversation
    association :mentioned, factory: :user
  end
end
