# frozen_string_literal: true

module Automations
  module Actions
    class SetLocale < BaseAction
      def call
        require_conversation!

        locale = params[:locale]
        raise "locale is required" if locale.blank?

        resource.update!(locale: locale)
      end
    end
  end
end
