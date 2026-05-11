# frozen_string_literal: true

module Automations
  class ExecutionWorker
    include Sidekiq::Worker
    sidekiq_options queue: "automations", retry: 2

    # Executes an Actionable record (Automation or Macro) against a resource.
    # Called by:
    #   - EventDispatcher (event_trigger rules)
    #   - TimeTriggerWorker (time_trigger rules)
    #   - MacrosController (manual macro execution)
    #
    # @param executable_type [String] "Automation" or "Macro"
    # @param executable_id [String] UUID of the Automation/Macro to execute
    # @param resource_type [String] "Conversation", "Customer", "Message"
    # @param resource_id [String] UUID of the target resource
    # @param triggered_by [String] "event", "schedule", or "manual"
    # @param cascade_depth [Integer] current cascade depth (prevents infinite loops)
    def perform(executable_type, executable_id, resource_type, resource_id, triggered_by = "event", cascade_depth = 0)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      executable = executable_type.constantize.find_by(id: executable_id)
      return unless executable&.active?

      resource = resource_type.constantize.find_by(id: resource_id)
      return unless resource

      account = executable.account

      # Execute all actions
      results = Automations::ActionExecutor.call(
        executable: executable,
        resource: resource,
        account: account
      )

      duration_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time
      has_failures = results.any? { |r| r["result"] == "failed" }

      # Log the execution
      AutomationExecution.create!(
        executable: executable,
        account: account,
        resource: resource,
        status: has_failures ? :failed : :success,
        triggered_by: triggered_by,
        executed_actions: results,
        error_message: has_failures ? results.select { |r| r["result"] == "failed" }.pluck("error").join("; ") : nil,
        execution_duration_ms: duration_ms,
        executed_at: Time.current
      )

      # Cascade: if this executable changed the resource, re-evaluate event triggers.
      # Only for Automation records (not Macros) within cascade depth.
      if executable.is_a?(Automation) &&
         cascade_depth < Automations::EventDispatcher::MAX_CASCADE_DEPTH &&
         executable.event_trigger?
        resource.reload
        Automations::EventDispatcher.call(
          event_name: "conversation.updated",
          payload: resource.respond_to?(:event_payload) ? resource.event_payload : {},
          account: account,
          cascade_depth: cascade_depth + 1
        )
      end

    rescue StandardError => e
      Rails.logger.error("[Automations::ExecutionWorker] Failed: #{e.message}")

      # Still log the failed execution if we have enough context
      if executable && resource
        duration_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time rescue 0
        AutomationExecution.create(
          executable: executable,
          account: executable.account,
          resource: resource,
          status: :failed,
          triggered_by: triggered_by,
          executed_actions: [],
          error_message: e.message,
          execution_duration_ms: duration_ms,
          executed_at: Time.current
        )
      end
    end
  end
end
