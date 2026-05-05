# frozen_string_literal: true

module Automations
  class ConditionEvaluator < ApplicationService
    attr_reader :conditions, :payload

    # Evaluates nested AND/OR condition groups against an event payload.
    #
    # conditions format:
    # {
    #   "operator" => "AND",
    #   "groups" => [
    #     {
    #       "operator" => "OR",
    #       "conditions" => [
    #         { "attribute" => "status", "operator" => "equals", "value" => "active" }
    #       ]
    #     }
    #   ]
    # }

    def initialize(conditions:, payload:)
      @conditions = conditions.with_indifferent_access
      @payload = payload.with_indifferent_access
    end

    def call
      return true if conditions.blank? || conditions["groups"].blank?

      groups = conditions["groups"]
      top_operator = conditions.fetch("operator", "AND").upcase

      results = groups.map { |group| evaluate_group(group) }

      case top_operator
      when "OR"  then results.any?
      else results.all?
      end
    end

    private

    def evaluate_group(group)
      group_conditions = group["conditions"] || []
      group_operator = group.fetch("operator", "AND").upcase

      results = group_conditions.map { |condition| evaluate_condition(condition) }

      case group_operator
      when "OR"  then results.any?
      else results.all?
      end
    end

    def evaluate_condition(condition)
      attribute = condition["attribute"]
      operator = condition["operator"]
      expected_value = condition["value"]

      actual_value = resolve_attribute(attribute)

      compare(actual_value, operator, expected_value)
    end

    # Resolve dotted attribute paths from the payload.
    # "status"           → payload["status"]
    # "inbox.name"       → payload["inbox"]["name"] (if nested)
    # "customer.email"   → payload["customer"]["email"]
    # "custom_field.xyz" → payload["data"]["xyz"] (reads from entity's data jsonb)
    # "labels"           → payload["labels"]
    def resolve_attribute(attribute)
      return nil if attribute.blank?

      if attribute.start_with?("custom_field.")
        # Custom field values are stored in the entity's data jsonb
        field_key = attribute.sub("custom_field.", "")
        payload.dig("data", field_key)
      elsif attribute.include?(".")
        # Dotted path: traverse nested hashes
        parts = attribute.split(".")
        parts.reduce(payload) { |data, key| data.is_a?(Hash) ? data[key] : nil }
      else
        payload[attribute]
      end
    end

    def compare(actual, operator, expected)
      case operator
      when "equals"
        normalize(actual) == normalize(expected)
      when "not_equals"
        normalize(actual) != normalize(expected)
      when "contains"
        return Array(actual).map { |v| normalize(v) }.include?(normalize(expected)) if actual.is_a?(Array)

        normalize(actual).to_s.include?(normalize(expected).to_s)
      when "not_contains"
        return Array(actual).map { |v| normalize(v) }.exclude?(normalize(expected)) if actual.is_a?(Array)

        normalize(actual).to_s.exclude?(normalize(expected).to_s)
      when "starts_with"
        normalize(actual).to_s.start_with?(normalize(expected).to_s)
      when "ends_with"
        normalize(actual).to_s.end_with?(normalize(expected).to_s)
      when "is_present"
        actual.present?
      when "is_not_present"
        actual.blank?
      when "greater_than"
        to_number(actual) > to_number(expected)
      when "less_than"
        to_number(actual) < to_number(expected)
      when "days_before"
        # Used for time_trigger: checks if a datetime is more than N days ago
        return false if actual.blank?

        parsed = actual.is_a?(String) ? Time.zone.parse(actual) : actual
        parsed.present? && parsed < to_number(expected).days.ago
      else
        false
      end
    rescue StandardError => e
      Rails.logger.warn("[Automations::ConditionEvaluator] Comparison failed: #{e.message}")
      false
    end

    def normalize(value)
      value.is_a?(String) ? value.strip.downcase : value
    end

    def to_number(value)
      Float(value)
    rescue ArgumentError, TypeError
      0
    end
  end
end
