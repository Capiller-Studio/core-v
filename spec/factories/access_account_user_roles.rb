FactoryBot.define do
  factory :access_account_user_role, class: 'Access::AccountUserRole' do
    account
    account_user
    association :role, factory: :access_role
  end
end
