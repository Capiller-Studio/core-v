# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_delivery, class: "Webhook::Delivery" do
    account
    resource { association(:channel_custom, account: account) }
    event_name { "conversation.created" }
    endpoint_url { "https://api.example.com/webhook" }
    request_payload { { event: "conversation.created", id: "123" } }
    status { :pending }
  end

  factory :webhook_delivery_attempt, class: "Webhook::DeliveryAttempt" do
    delivery { association(:webhook_delivery) }
    attempt_number { 1 }
    http_status { 200 }
  end
end
