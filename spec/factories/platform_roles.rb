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

    trait :admin do
      name { 'Administrator' }
      identifier { 'admin' }
      permissions do
        Platform::Role::PERMISSION_SCHEMA.transform_values(&:dup).merge('staff' => ['read'])
      end
    end

    trait :support do
      name { 'Support Lead' }
      identifier { 'support' }
      permissions do
        {
          'accounts' => %w[read manage],
          'users' => %w[read manage],
          'plans' => %w[read],
          'subscriptions' => %w[read],
          'transactions' => %w[read],
          'channels' => %w[read manage],
          'domains' => %w[read manage],
          'system_logs' => %w[read]
        }
      end
    end

    trait :finance do
      name { 'Finance & Billing' }
      identifier { 'finance' }
      permissions do
        {
          'accounts' => %w[read],
          'users' => %w[read],
          'plans' => %w[read manage],
          'subscriptions' => %w[read manage],
          'transactions' => %w[read manage],
          'affiliates' => %w[read],
          'commissions' => %w[read manage],
          'referrals' => %w[read],
          'payouts' => %w[read manage],
          'payout_batches' => %w[read manage],
          'system_logs' => %w[read]
        }
      end
    end

    trait :read_only do
      name { 'Auditor' }
      identifier { 'read_only' }
      permissions do
        Platform::Role::PERMISSION_SCHEMA.transform_values { |_actions| ['read'] }
      end
    end
  end
end
