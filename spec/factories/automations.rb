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
  end
end
