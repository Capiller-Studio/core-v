# frozen_string_literal: true

module Automations
  module Actions
    class AddNote < BaseAction
      def call
        require_conversation!

        content = params[:content]
        raise "content is required" if content.blank?

        # Internal note: visibility is "personal" so customers don't see it
        resource.messages.create!(
          account: account,
          inbox: resource.inbox,
          content: content,
          visibility: :personal,
          content_type: :activity,
          sender: system_sender,
          source: resource.source
        )
      end

      private

      def system_sender
        AccountUser.find_by(account: account, role: :owner)&.user ||
          AccountUser.find_by(account: account, role: :admin)&.user
      end
    end
  end
end
