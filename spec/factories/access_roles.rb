FactoryBot.define do
  factory :access_role, class: 'Access::Role' do
    account
    sequence(:name) { |n| "Role #{n}" }
    system_provided { false }
    permissions { { "conversations" => ["read"] } }
  end
end
