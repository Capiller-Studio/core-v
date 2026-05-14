FactoryBot.define do
  factory :team_user do
    team
    user
    role { :member }
  end
end
