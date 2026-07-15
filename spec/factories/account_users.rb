FactoryBot.define do
  factory :account_user do
    account
    user
    status { :active }
  end
end
