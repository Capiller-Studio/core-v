FactoryBot.define do
  factory :user do
    name { FFaker::Name.name }
    sequence(:email) { |n| "user_#{n}_#{SecureRandom.hex(4)}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    locale { 'en' }
    address
  end
end
