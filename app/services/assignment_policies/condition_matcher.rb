# frozen_string_literal: true

module AssignmentPolicies
  # Evaluates an assignment policy's conditions against a conversation.
  #
  # Reuses the exact same condition schema as Automations:
  # {
  #   "operator": "AND",
  #   "groups": [
  #     {
  #       "operator": "OR",
  #       "conditions": [
  #         { "attribute": "priority", "operator": "equals", "value": "urgent" }
  #       ]
  #     }
  #   ]
  # }
  #
  # Returns true if ALL conditions are met, false otherwise.
  #
  class ConditionMatcher < ApplicationService
    attr_reader :policy, :conversation

    def initialize(policy:, conversation:)
      @policy = policy
      @conversation = conversation
    end

    def call
      conditions = policy.conditions
      return true if conditions.blank? || conditions == {}

      top_operator = conditions["operator"] || "AND"
      groups = conditions["groups"] || []
      return true if groups.empty?

      evaluate_groups(groups, top_operator)
    end

    private

    def evaluate_groups(groups, operator)
      results = groups.map { |group| evaluate_group(group) }

      case operator
      when "AND" then results.all?
      when "OR"  then results.any?
      else results.all?
      end
    end

    def evaluate_group(group)
      group_operator = group["operator"] || "AND"
      conditions = group["conditions"] || []
      return true if conditions.empty?

      results = conditions.map { |condition| evaluate_condition(condition) }

      case group_operator
      when "AND" then results.all?
      when "OR"  then results.any?
      else results.all?
      end
    end

    def evaluate_condition(condition)
      attribute = condition["attribute"]
      operator = condition["operator"]
      expected = condition["value"]

      actual = resolve_attribute(attribute)

      compare(actual, operator, expected)
    end

    def resolve_attribute(attribute)
      case attribute
      # Conversation attributes
      when "status"     then conversation.status
      when "priority"   then conversation.priority
      when "source"     then conversation.source
      when "locale"     then conversation.locale
      when "title"      then conversation.title
      when "identifier" then conversation.identifier

      # Inbox attributes
      when "inbox.id"           then conversation.inbox_id
      when "inbox.name"         then conversation.inbox&.name
      when "inbox.channel_type" then conversation.inbox&.channel_type

      # Team attributes
      when "team.id"   then conversation.team_id
      when "team.name" then conversation.team&.name

      # Assignee attributes
      when "assignee.id"    then conversation.assignee&.id
      when "assignee.name"  then conversation.assignee&.name
      when "assignee.email" then conversation.assignee&.email

      # Customer attributes — first customer in the conversation
      when "customer.email"         then first_customer&.email
      when "customer.name"          then first_customer&.name
      when "customer.locale"        then first_customer&.locale
      when "customer.customer_type" then first_customer&.customer_type

      # Custom fields — reads from conversation data jsonb
      when /\Acustom_field\.(.*)\z/
        conversation.data&.dig($1)

      else
        nil
      end
    end

    def first_customer
      @first_customer ||= conversation.customers.first
    end

    def compare(actual, operator, expected)
      case operator
      when "equals"
        actual.to_s.downcase == expected.to_s.downcase
      when "not_equals"
        actual.to_s.downcase != expected.to_s.downcase
      when "contains"
        actual.to_s.downcase.include?(expected.to_s.downcase)
      when "not_contains"
        !actual.to_s.downcase.include?(expected.to_s.downcase)
      when "starts_with"
        actual.to_s.downcase.start_with?(expected.to_s.downcase)
      when "ends_with"
        actual.to_s.downcase.end_with?(expected.to_s.downcase)
      when "is_present"
        actual.present?
      when "is_not_present"
        actual.blank?
      when "greater_than"
        actual.to_f > expected.to_f
      when "less_than"
        actual.to_f < expected.to_f
      else
        false
      end
    end
  end
end
