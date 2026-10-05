# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Macros
  # Runs a macro synchronously against a conversation on behalf of an agent.
  #
  # Unlike automations (which run in Sidekiq), macros are triggered by an agent
  # clicking "Run" and expect immediate feedback, so actions execute inline.
  # Slow side-effects (channel delivery, emails, webhooks) are still handed off
  # to workers by the individual action handlers.
  #
  # Every run is logged as an AutomationExecution (triggered_by: :manual) and
  # recorded as a "macro_executed" activity on the conversation timeline.
  #
  # Usage:
  #   result = Macros::Executor.call(macro: macro, conversation: conversation, actor: current_user)
  #   result.success?   # all actions succeeded
  #   result.partial?   # some actions failed
  #   result.failed?    # every action failed
  class Executor < ApplicationService
    class InactiveMacroError < StandardError; end

    Result = Struct.new(:status, :results, :execution, keyword_init: true) do
      def success? = status == :success
      def partial? = status == :partial
      def failed? = status == :failed

      def failed_results
        results.select { |r| r["result"] == "failed" }
      end

      def succeeded_count
        results.count { |r| r["result"] == "success" }
      end
    end

    attr_reader :macro, :conversation, :actor, :account

    def initialize(macro:, conversation:, actor:)
      @macro = macro
      @conversation = conversation
      @actor = actor
      @account = macro.account
    end

    def call
      raise(InactiveMacroError, "Macro is inactive") unless macro.active?

      started_at = monotonic_ms
      results = Automations::ActionExecutor.call(
        executable: macro,
        resource: conversation,
        account: account,
        actor: actor
      )

      status = resolve_status(results)
      execution = log_execution(results, status, monotonic_ms - started_at)
      record_activity(status)

      conversation.reload
      Result.new(status: status, results: results, execution: execution)
    end

    private

    def resolve_status(results)
      failures = results.count { |r| r["result"] == "failed" }

      if failures.zero?
        :success
      elsif failures == results.size
        :failed
      else
        :partial
      end
    end

    def log_execution(results, status, duration_ms)
      errors = results.filter_map { |r| r["error"] if r["result"] == "failed" }

      AutomationExecution.create!(
        executable: macro,
        account: account,
        resource: conversation,
        status: status == :success ? :success : :failed,
        triggered_by: :manual,
        executed_actions: results,
        error_message: errors.presence&.join("; "),
        execution_duration_ms: duration_ms,
        executed_at: Time.current
      )
    rescue StandardError => e
      # Logging must never break the agent's workflow.
      Rails.logger.error("[Macros::Executor] Failed to log execution for macro #{macro.id}: #{e.message}")
      nil
    end

    def record_activity(status)
      return if status == :failed

      Activities::Recorder.call(
        trackable: conversation,
        event_type: "macro_executed",
        changes: { macro: macro.name },
        actor: actor,
        account: account
      )
    rescue StandardError => e
      Rails.logger.error("[Macros::Executor] Failed to record activity for macro #{macro.id}: #{e.message}")
    end

    def monotonic_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end
