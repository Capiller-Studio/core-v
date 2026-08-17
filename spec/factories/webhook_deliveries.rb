# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_delivery, class: "Webhook::Delivery" do
    association :resource, factory: :channel_custom
    event_name { "conversation.created" }
    endpoint_url { "https://api.example.com/webhook" }
    request_payload { { event: "conversation.created", id: "123" } }
    status { :pending }
  end

  factory :webhook_delivery_attempt, class: "Webhook::DeliveryAttempt" do
    association :delivery, factory: :webhook_delivery
    attempt_number { 1 }
    http_status { 200 }
  end
end
