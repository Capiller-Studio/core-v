FactoryBot.define do
  factory :account_invitation do
    account
    association :invited_by, factory: :user
    sequence(:email) { |n| "user#{n}@example.com" }
    role_ids { [SecureRandom.uuid] }
    status { :pending }
  end
end
