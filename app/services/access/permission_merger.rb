# frozen_string_literal: true

module Access
  class PermissionMerger < ApplicationService
    def initialize(permissions_list, resource_type, action, resource = nil)
      @permissions_list = permissions_list
      @resource_type = resource_type
      @action = action
      @resource = resource
    end

    def call
      return false if @permissions_list.empty?

      # Additive Logic: If ANY role grants permission, allow it.
      @permissions_list.any? do |permissions|
        policy = permissions.dig(@resource_type, @action)
        manage_policy = permissions.dig(@resource_type, "manage")

        # A role grants access if it explicitly grants the action OR grants "manage" capability
        evaluate_policy(policy) || (@action != "manage" && evaluate_policy(manage_policy))
      end
    end

    private

    def evaluate_policy(policy)
      return false if policy.nil? || policy == false
      return true if policy == true

      if policy.is_a?(Hash)
        evaluate_conditions(policy)
      else
        false
      end
    end

    private

    def evaluate_conditions(conditions)
      return true if @resource.nil? # General capability check

      # All keys within a single role's hash must match (AND logic)
      conditions.all? do |key, values|
        allowed_values = Array(values).map(&:to_s)

        case key
        when "inbox_ids"
          @resource.respond_to?(:inbox_id) && allowed_values.include?(@resource.inbox_id.to_s)
        when "ids"
          allowed_values.include?(@resource.id.to_s)
        else
          false # Unknown condition key fails
        end
      end
    end
  end
end
