# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Automations
  # Validates the actions JSONB array structure.
  # Shared between Automation and Macro models via the Actionable concern.
  class ActionsValidator < ApplicationService
    attr_reader :actions, :errors

    VALID_ACTIONS = ActionExecutor::ACTION_HANDLERS.keys.freeze

    # Blocked URL patterns for webhook SSRF prevention
    BLOCKED_URL_PATTERNS = [
      /\Ahttps?:\/\/localhost/i,
      /\Ahttps?:\/\/127\./,
      /\Ahttps?:\/\/10\./,
      /\Ahttps?:\/\/172\.(1[6-9]|2\d|3[01])\./,
      /\Ahttps?:\/\/192\.168\./,
      /\Ahttps?:\/\/0\.0\.0\.0/,
      /\Ahttps?:\/\/\[::1\]/
    ].freeze

    def initialize(actions:)
      @actions = actions
      @errors = []
    end

    def call
      validate_actions
      errors
    end

    def valid?
      call
      errors.empty?
    end

    private

    def validate_actions
      unless actions.is_a?(Array)
        errors << "actions must be an array"
        return
      end

      if actions.empty?
        errors << "at least one action is required"
        return
      end

      actions.each_with_index do |action, idx|
        validate_single_action(action, idx)
      end
    end

    def validate_single_action(action, idx)
      prefix = "actions[#{idx}]"

      unless action.is_a?(Hash)
        errors << "#{prefix} must be a JSON object"
        return
      end

      action_name = action["action"]

      if action_name.blank?
        errors << "#{prefix}.action is required"
      elsif !VALID_ACTIONS.include?(action_name)
        errors << "#{prefix}.action '#{action_name}' is not valid"
      else
        validate_action_params(action_name, action["params"] || {}, prefix)
      end
    end

    def validate_action_params(action_name, params, prefix)
      case action_name
      when "assign_agent"
        errors << "#{prefix}.params.agent_id is required" if params["agent_id"].blank?
      when "assign_team"
        errors << "#{prefix}.params.team_id is required" if params["team_id"].blank?
      when "set_status"
        unless %w[active closed snoozed resolved].include?(params["status"])
          errors << "#{prefix}.params.status must be active, closed, snoozed, or resolved"
        end
      when "set_priority"
        unless %w[low medium high urgent].include?(params["priority"])
          errors << "#{prefix}.params.priority must be low, medium, high, or urgent"
        end
      when "add_label", "remove_label"
        errors << "#{prefix}.params.label_ids is required" if params["label_ids"].blank?
      when "set_custom_field"
        errors << "#{prefix}.params.key is required" if params["key"].blank?
      when "send_message"
        errors << "#{prefix}.params.content is required" if params["content"].blank?
      when "send_email_to_customer", "send_email_to_team"
        errors << "#{prefix}.params.email_template_id is required" if params["email_template_id"].blank?
      when "add_note"
        errors << "#{prefix}.params.content is required" if params["content"].blank?
      when "snooze"
        errors << "#{prefix}.params.duration_hours is required" if params["duration_hours"].blank?
      when "set_locale"
        errors << "#{prefix}.params.locale is required" if params["locale"].blank?
      when "trigger_webhook"
        validate_webhook_params(params, prefix)
      end
    end

    def validate_webhook_params(params, prefix)
      url = params["url"]

      if url.blank?
        errors << "#{prefix}.params.url is required"
        return
      end

      unless url.match?(/\Ahttps?:\/\//i)
        errors << "#{prefix}.params.url must be a valid HTTP(S) URL"
        return
      end

      BLOCKED_URL_PATTERNS.each do |pattern|
        if url.match?(pattern)
          errors << "#{prefix}.params.url cannot target internal or private network addresses"
          return
        end
      end

      method = params["method"]
      if method.present? && !%w[GET POST PUT PATCH].include?(method.upcase)
        errors << "#{prefix}.params.method must be GET, POST, PUT, or PATCH"
      end
    end
  end
end
