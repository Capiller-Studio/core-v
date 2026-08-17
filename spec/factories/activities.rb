# frozen_string_literal: true

FactoryBot.define do
  factory :activity do
    account
    association :trackable, factory: :conversation
    association :actor, factory: :user
    event_key { 'conversation.updated' }
    object_changes { {} }
    object_snapshot { {} }
  end
end
