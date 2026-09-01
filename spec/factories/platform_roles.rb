# frozen_string_literal: true

FactoryBot.define do
  factory :platform_role, class: 'Platform::Role' do
    name { FFaker::Job.title }
    sequence(:identifier) { |n| "role_#{n}" }
    permissions { { 'system_logs' => ['read', 'manage'] } }

    trait :super_admin do
      name { 'Super Admin' }
      identifier { 'super_admin' }
      permissions do
        Platform::Role::PERMISSION_SCHEMA.transform_values { |actions| actions }
      end
    end
  end
end
