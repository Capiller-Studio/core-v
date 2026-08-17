# frozen_string_literal: true

FactoryBot.define do
  factory :customer_inbox do
    customer
    inbox
    external_id { SecureRandom.hex(8) }
    connection_token { SecureRandom.hex(16) }
  end
end
