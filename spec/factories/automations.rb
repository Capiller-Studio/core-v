FactoryBot.define do
  factory :automation do
    account
    name { 'Auto Assign VIP' }
    automation_type { :event_trigger }
    event_name { 'conversation.created' }
    status { :active }
    conditions { { operator: 'AND', groups: [] } }
    actions { [] }
    configurations { {} }
    
    trait :macro do
      automation_type { :macro }
      user
      event_name { nil }
    end
  end
end
