# frozen_string_literal: true

FactoryBot.define do
  factory :platform_staff, class: 'Platform::Staff' do
    name { FFaker::Name.name }
    email { FFaker::Internet.email }
    password { 'Password123!' }
    password_confirmation { 'Password123!' }
    status { :active }

    trait :active do
      status { :active }
    end

    trait :suspended do
      status { :suspended }
    end

    trait :deactivated do
      status { :deactivated }
    end

    trait :super_admin do
      after(:create) do |staff|
        role = Platform::Role.find_by(identifier: 'super_admin') || create(:platform_role, :super_admin)
        staff.roles << role unless staff.roles.include?(role)
      end
    end

    trait :admin do
      after(:create) do |staff|
        role = Platform::Role.find_by(identifier: 'admin') || create(:platform_role, :admin)
        staff.roles << role unless staff.roles.include?(role)
      end
    end
  end
end
