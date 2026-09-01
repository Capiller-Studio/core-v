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
  end
end
