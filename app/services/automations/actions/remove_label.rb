# frozen_string_literal: true

module Automations
  module Actions
    class RemoveLabel < BaseAction
      def call
        require_conversation!

        label_ids = Array(params[:label_ids])
        raise "label_ids is required" if label_ids.blank?

        # Remove the association via the labeling join table
        resource.labels.where(id: label_ids).each do |label|
          resource.labels.delete(label)
        end
      end
    end
  end
end
