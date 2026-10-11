# frozen_string_literal: true

FactoryBot.define do
  factory :customer_device do
    account
    inbox
    customer
    customer_inbox
    push_token { SecureRandom.hex(32) }
    platform { :ios }
    push_provider { :apns }
    status { :active }
    device_model { "iPhone 15 Pro" }
    os_version { "iOS 18.0" }
    app_version { "1.0.0" }
  end
end
