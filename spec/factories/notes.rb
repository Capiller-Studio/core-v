# frozen_string_literal: true

FactoryBot.define do
  factory :note do
    account
    user
    association :resource, factory: :conversation
    content { 'Internal agent note' }
    visibility { :personal }
  end
end
