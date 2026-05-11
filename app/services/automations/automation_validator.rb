# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Automations
  # Validates the conditions JSONB structure for Automation models.
  # Actions validation is handled by ActionsValidator (shared with Macro via Actionable concern).
  class AutomationValidator < ApplicationService
    attr_reader :conditions, :errors

    VALID_TOP_OPERATORS = %w[AND OR].freeze

    VALID_CONDITION_OPERATORS = %w[
      equals not_equals contains not_contains starts_with ends_with
      is_present is_not_present greater_than less_than days_before
    ].freeze

    # Whitelist of allowed condition attributes.
    # This prevents arbitrary attribute access or injection.
    VALID_CONDITION_ATTRIBUTES = %w[
      status priority source locale title identifier
      inbox.id inbox.name inbox.channel_type
      assignee.id assignee.name assignee.email
      team.id team.name
      customer.email customer.name customer.locale customer.customer_type
      message.content message.content_type message.sender_type
      labels
      hours_since_created hours_since_updated hours_since_resolved hours_since_last_activity
    ].freeze

    CUSTOM_FIELD_PREFIX = "custom_field.".freeze

    def initialize(conditions:)
      @conditions = conditions
      @errors = []
    end

    def call
      validate_conditions if conditions.present?
      errors
    end

    def valid?
      call
      errors.empty?
    end

    private

    def validate_conditions
      unless conditions.is_a?(Hash)
        errors << "conditions must be a JSON object"
        return
      end

      top_operator = conditions["operator"]
      if top_operator.present? && !VALID_TOP_OPERATORS.include?(top_operator.upcase)
        errors << "conditions.operator must be AND or OR"
      end

      groups = conditions["groups"]
      return if groups.blank?

      unless groups.is_a?(Array)
        errors << "conditions.groups must be an array"
        return
      end

      groups.each_with_index do |group, idx|
        validate_condition_group(group, idx)
      end
    end

    def validate_condition_group(group, group_idx)
      unless group.is_a?(Hash)
        errors << "conditions.groups[#{group_idx}] must be a JSON object"
        return
      end

      group_operator = group["operator"]
      if group_operator.present? && !VALID_TOP_OPERATORS.include?(group_operator.upcase)
        errors << "conditions.groups[#{group_idx}].operator must be AND or OR"
      end

      conditions_list = group["conditions"]
      return if conditions_list.blank?

      unless conditions_list.is_a?(Array)
        errors << "conditions.groups[#{group_idx}].conditions must be an array"
        return
      end

      conditions_list.each_with_index do |condition, cond_idx|
        validate_single_condition(condition, group_idx, cond_idx)
      end
    end

    def validate_single_condition(condition, group_idx, cond_idx)
      prefix = "conditions.groups[#{group_idx}].conditions[#{cond_idx}]"

      unless condition.is_a?(Hash)
        errors << "#{prefix} must be a JSON object"
        return
      end

      attribute = condition["attribute"]
      operator = condition["operator"]

      if attribute.blank?
        errors << "#{prefix}.attribute is required"
      elsif !valid_attribute?(attribute)
        errors << "#{prefix}.attribute '#{attribute}' is not allowed"
      end

      if operator.blank?
        errors << "#{prefix}.operator is required"
      elsif !VALID_CONDITION_OPERATORS.include?(operator)
        errors << "#{prefix}.operator '#{operator}' is not valid"
      end

      if %w[is_present is_not_present].exclude?(operator) && condition["value"].nil?
        errors << "#{prefix}.value is required for operator '#{operator}'"
      end
    end

    def valid_attribute?(attribute)
      return true if VALID_CONDITION_ATTRIBUTES.include?(attribute)
      return true if attribute.start_with?(CUSTOM_FIELD_PREFIX)

      false
    end
  end
end
