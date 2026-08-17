# frozen_string_literal: true

FactoryBot.define do
  factory :notification_subscription do
    user
    name { 'Chrome Desktop' }
    subscription_type { :push }
    data { { 'endpoint' => 'https://fcm.googleapis.com/fcm/send/test', 'p256dh' => 'key', 'auth' => 'secret' } }
    configurations { {} }
  end
end
