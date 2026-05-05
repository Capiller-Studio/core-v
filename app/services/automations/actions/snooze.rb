# frozen_string_literal: true

module Automations
  module Actions
    class Snooze < BaseAction
      def call
        require_conversation!

        duration_hours = params[:duration_hours].to_i
        raise("duration_hours must be positive") unless duration_hours.positive?

        resource.update!(
          status: :snoozed,
          # Store snooze_until in configurations so a scheduled worker can un-snooze it
          configurations: resource.configurations.merge(
            "snoozed_until" => duration_hours.hours.from_now.iso8601
          )
        )
      end
    end
  end
end
