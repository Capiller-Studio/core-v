# frozen_string_literal: true

module Automations
  module Actions
    class AddLabel < BaseAction
      def call
        require_conversation!

        label_ids = Array(params[:label_ids])
        raise "label_ids is required" if label_ids.blank?

        labels = account.labels.where(id: label_ids)

        labels.each do |label|
          # Uses the labeling join table — resource.labels << label
          # Skips silently if already attached (no duplicates)
          resource.labels << label unless resource.labels.include?(label)
        end
      end
    end
  end
end
