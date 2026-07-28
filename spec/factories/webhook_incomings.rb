# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_incoming, class: "Webhook::Incoming" do
    source { "stripe" }
    event_type { nil }
    request_url { "https://app.deskbolic.com/webhooks/stripe" }
    headers { { "HTTP_CONTENT_TYPE" => "application/json" } }
    payload { { "id" => "evt_test", "type" => "charge.refunded" } }
    status { :pending }
    fail_safe_retries { 0 }
    error_message { nil }
  end
end
