# frozen_string_literal: true

module Automations
  class EventDispatcher < ApplicationService
    attr_reader :event_name, :payload, :account

    MAX_CASCADE_DEPTH = 3

    def initialize(event_name:, payload:, account:, cascade_depth: 0)
      @event_name = event_name
      @payload = payload
      @account = account
      @cascade_depth = cascade_depth
    end

    def call
      return unless account
      return if @cascade_depth >= MAX_CASCADE_DEPTH

      rules = account.automations.event_triggers_for(event_name)
      return if rules.empty?

      rules.each do |rule|
        next unless conditions_match?(rule, payload)

        Automations::ExecutionWorker.perform_async(
          rule.id,
          resource_type,
          resource_id,
          "event",
          @cascade_depth
        )

        break if rule.stop_processing?
      end
    rescue StandardError => e
      Rails.logger.error("[Automations::EventDispatcher] Failed for event '#{event_name}': #{e.message}")
    end

    private

    def conditions_match?(rule, payload)
      return true if rule.conditions.blank? || rule.conditions["groups"].blank?

      Automations::ConditionEvaluator.call(
        conditions: rule.conditions,
        payload: payload
      )
    end

    # Extract the resource type and ID from the event payload.
    # Conversation events have id at top level; message events nest conversation data.
    def resource_type
      if event_name.start_with?("message.")
        "Message"
      elsif event_name.start_with?("customer.")
        "Customer"
      else
        "Conversation"
      end
    end

    def resource_id
      payload["id"]
    end
  end
end
