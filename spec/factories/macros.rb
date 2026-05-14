FactoryBot.define do
  factory :macro do
    account
    name { 'Close & Thank' }
    status { :active }
    visibility { :account_wide }
    actions { [
      { action: 'set_status', params: { status: 'resolved' } },
      { action: 'send_message', params: { content: 'Thank you!', visibility: 'global' } }
    ] }

    trait :personal do
      visibility { :personal }
      association :scopeable, factory: :user
    end

    trait :team do
      visibility { :team }
      association :scopeable, factory: :team
    end
  end
end
