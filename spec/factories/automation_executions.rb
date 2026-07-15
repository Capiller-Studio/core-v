FactoryBot.define do
  factory :automation_execution do
    account
    association :executable, factory: :automation
    association :resource, factory: :conversation
    status { :success }
    triggered_by { :event }
    executed_at { Time.current }
    executed_actions { [] }
  end
end
