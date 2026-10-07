# frozen_string_literal: true

module Integrations
  class EventDispatcher < ApplicationService
    attr_reader :event_name, :payload, :account

    def initialize(event_name:, payload:, account:)
      @event_name = event_name
      @payload = payload
      @account = account
    end

    def call
      return unless account

      active_integrations = account.integrations.active

      active_integrations.each do |integration|
        case integration.provider
        when "webhook"
          dispatch_to_webhook(integration)
        when "slack"
          dispatch_to_slack(integration)
        end
      end
    rescue StandardError => e
      Rails.logger.error("Integration Dispatcher Failed dynamically: #{e.message}")
    end

    private

    def dispatch_to_webhook(integration)
      return unless integration.subscribed_events.include?(event_name) || integration.subscribed_events.include?("*")

      if integration.subscribed_inboxes.any?
        target_inbox_id = payload["inbox_id"] || payload.dig("conversation", "inbox_id")
        return unless integration.subscribed_inboxes.include?(target_inbox_id)
      end

      url = integration.webhook_url
      return unless url

      delivery = Webhook::Delivery.create!(
        account: account,
        resource: integration,
        event_name: event_name,
        endpoint_url: url,
        request_payload: payload,
        status: :pending
      )

      Integrations::Webhooks::BroadcasterWorker.perform_async(account.id, delivery.id, 1)
    end

    def dispatch_to_slack(integration)
      return unless integration.subscribed_events.include?(event_name)

      url = integration.webhook_url
      return unless url

      delivery = Webhook::Delivery.create!(
        account: account,
        resource: integration,
        event_name: event_name,
        endpoint_url: url,
        request_payload: payload,
        status: :pending
      )

      Integrations::Slack::NotifierWorker.perform_async(account.id, delivery.id, 1)
    end
  end
end
