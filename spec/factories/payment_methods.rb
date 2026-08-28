# frozen_string_literal: true

FactoryBot.define do
  factory :payment_method do
    account
    provider { :stripe }
    payment_type { :card }
    status { :active }
    external_id { "pm_#{SecureRandom.hex(8)}" }
    brand { 'Visa' }
    last_four { '4242' }
    expiry_month { 12 }
    expiry_year { 2030 }
    default_method { false }

    trait :default do
      default_method { true }
    end
  end
end
