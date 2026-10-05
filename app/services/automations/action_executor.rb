# frozen_string_literal: true

module Automations
  class ActionExecutor < ApplicationService
    attr_reader :executable, :resource, :account, :actor

    # Executes all actions defined in an Actionable record against a resource.
    # Works with both Automation and Macro models.
    # Returns an array of action result hashes for the execution log.
    #
    # Usage:
    #   results = Automations::ActionExecutor.call(
    #     executable: rule_or_macro,
    #     resource: conversation,
    #     account: account,
    #     actor: current_user # optional — set for manual macro runs
    #   )
    #   # => [{ "action" => "assign_agent", "params" => {...}, "result" => "success" }, ...]

    ACTION_HANDLERS = {
      "assign_agent"           => Automations::Actions::AssignAgent,
      "assign_team"            => Automations::Actions::AssignTeam,
      "unassign"               => Automations::Actions::Unassign,
      "set_status"             => Automations::Actions::SetStatus,
      "set_priority"           => Automations::Actions::SetPriority,
      "add_label"              => Automations::Actions::AddLabel,
      "remove_label"           => Automations::Actions::RemoveLabel,
      "set_custom_field"       => Automations::Actions::SetCustomField,
      "send_message"           => Automations::Actions::SendMessage,
      "send_email_to_customer" => Automations::Actions::SendEmailToCustomer,
      "send_email_to_team"     => Automations::Actions::SendEmailToTeam,
      "add_note"               => Automations::Actions::AddNote,
      "snooze"                 => Automations::Actions::Snooze,
      "resolve"                => Automations::Actions::Resolve,
      "mute_conversation"      => Automations::Actions::MuteConversation,
      "trigger_webhook"        => Automations::Actions::TriggerWebhook,
      "set_locale"             => Automations::Actions::SetLocale
    }.freeze

    def initialize(executable:, resource:, account:, actor: nil)
      @executable = executable
      @resource = resource
      @account = account
      @actor = actor
    end

    def call
      actions = executable.actions || []
      results = []

      actions.each do |action_config|
        action_name = action_config["action"]
        params = action_config["params"] || {}
        handler_class = ACTION_HANDLERS[action_name]

        if handler_class.nil?
          results << {
            "action" => action_name,
            "params" => params,
            "result" => "failed",
            "error" => "Unknown action: #{action_name}"
          }
          next
        end

        begin
          handler_class.call(
            resource: resource,
            account: account,
            params: params,
            actor: actor
          )

          results << {
            "action" => action_name,
            "params" => params,
            "result" => "success"
          }
        rescue StandardError => e
          Rails.logger.error("[Automations::ActionExecutor] Action '#{action_name}' failed: #{e.message}")
          results << {
            "action" => action_name,
            "params" => params,
            "result" => "failed",
            "error" => e.message
          }
        end
      end

      results
    end
  end
end
