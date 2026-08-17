# frozen_string_literal: true

FactoryBot.define do
  factory :filter do
    account
    user
    name { 'Open VIP Conversations' }
    filter_type { :conversation }
    conditions { { "status" => "open", "priority" => "high" } }
  end
end
