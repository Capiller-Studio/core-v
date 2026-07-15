FactoryBot.define do
  factory :business_hour do
    business_hour_group
    account
    day_of_week { :monday }
    opening_time { '09:00' }
    closing_time { '17:00' }
  end
end
