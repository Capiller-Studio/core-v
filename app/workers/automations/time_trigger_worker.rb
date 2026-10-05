# frozen_string_literal: true

module Automations
  class TimeTriggerWorker
    include Sidekiq::Worker
    sidekiq_options queue: "automations", retry: 1

    # Runs hourly via Sidekiq cron (configure in sidekiq.yml or sidekiq-cron config).
    # Evaluates all active time_trigger automations across all accounts on this shard.
    #
    # Cron config example:
    #   automations_time_trigger:
    #     cron: "0 * * * *"  # Every hour at :00
    #     class: "Automations::TimeTriggerWorker"

    def perform
      active_shards = Account.distinct.pluck(:shard_key)

      active_shards.each do |shard_key|
        ShardRecord.connected_to(shard: shard_key.to_sym, role: :writing) do
          Automation.time_triggers.includes(:account).find_each do |rule|
            next unless rule.account

            begin
              rule.account.with_shard do
                process_rule(rule)
              end
            rescue StandardError => e
              Rails.logger.error("[Automations::TimeTriggerWorker] Rule #{rule&.id} failed: #{e.message}")
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("[Automations::TimeTriggerWorker] Shard #{shard_key} failed: #{e.message}")
      end
    end

    private

    def process_rule(rule)
      conversations = find_matching_conversations(rule)

      conversations.find_each do |conversation|
        payload = conversation.event_payload.stringify_keys

        # Check non-time conditions (e.g., "priority equals urgent")
        next unless conditions_match?(rule, payload)

        Automations::ExecutionWorker.perform_async(
          "Automation",
          rule.id,
          "Conversation",
          conversation.id,
          "schedule",
          0
        )
      end
    end

    # Query conversations matching the time-based event condition.
    # This is the initial filter — further conditions are evaluated in-memory.
    def find_matching_conversations(rule)
      account = rule.account
      conversations = account.conversations.where(status: [ :active, :snoozed ])

      # Extract time threshold from the first time-based condition
      hours = extract_hours_threshold(rule)
      return Conversation.none unless hours

      case rule.event_name
      when "hours_since_created"
        conversations.where(conversations: { created_at: ...hours.hours.ago })
      when "hours_since_updated"
        conversations.where(conversations: { updated_at: ...hours.hours.ago })
      when "hours_since_resolved"
        conversations.where(status: :resolved)
                     .where(conversations: { status_changed_at: ...hours.hours.ago })
      when "hours_since_last_activity"
        conversations.where(conversations: { last_activity_at: ...hours.hours.ago })
      else
        Conversation.none
      end
    end

    # Extract the hours threshold from conditions.
    # Looks for a condition with attribute matching the event_name.
    # Example: { "attribute": "hours_since_created", "operator": "greater_than", "value": "24" }
    def extract_hours_threshold(rule)
      return nil if rule.conditions.blank?

      groups = rule.conditions["groups"] || []
      groups.each do |group|
        (group["conditions"] || []).each do |condition|
          if condition["attribute"] == rule.event_name && condition["operator"] == "greater_than"
            return condition["value"].to_i
          end
        end
      end

      nil
    end

    def conditions_match?(rule, payload)
      return true if rule.conditions.blank? || rule.conditions["groups"].blank?

      filtered_groups = (rule.conditions["groups"] || []).filter_map do |group|
        filtered_conditions = (group["conditions"] || []).reject do |c|
          c["attribute"] == rule.event_name
        end
        next if filtered_conditions.empty?

        group.merge("conditions" => filtered_conditions)
      end

      return true if filtered_groups.empty?

      Automations::ConditionEvaluator.call(
        conditions: rule.conditions.merge("groups" => filtered_groups),
        payload: payload
      )
    end
  end
end
