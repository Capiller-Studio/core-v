# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    account
    user
    association :resource, factory: :conversation
    event { :conversation_created }
  end

  factory :notification_setting do
    account
    user
    configurations { {} }
  end
end
