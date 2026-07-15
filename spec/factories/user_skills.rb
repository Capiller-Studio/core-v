FactoryBot.define do
  factory :user_skill do
    account
    user
    skill
    proficiency { :beginner }
  end
end
