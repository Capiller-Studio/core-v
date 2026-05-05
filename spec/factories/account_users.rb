FactoryBot.define do
  factory :account_user do
    account
    user
    role { :agent }
    status { :active }
  end
end
