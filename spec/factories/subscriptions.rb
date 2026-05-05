FactoryBot.define do
  factory :subscription do
    account
    plan
    status { :active }
    billing_cycle { :monthly }
    provider { :stripe }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }
    data { {} }

    trait :trialing do
      status { :trialing }
      trial_start_at { Time.current }
      trial_end_at { 14.days.from_now }
    end
  end
end
