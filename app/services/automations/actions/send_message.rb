# frozen_string_literal: true

module Automations
  module Actions
    class SendMessage < BaseAction
      def call
        require_conversation!

        content = params[:content]
        raise("content is required") if content.blank?

        visibility = params.fetch(:visibility, "global")

        # Send as a system/bot message — sender is nil (system-generated)
        # or use a designated bot user if one exists on the account
        resource.messages.create!(
          account: account,
          inbox: resource.inbox,
          content: content,
          visibility: visibility,
          content_type: :text,
          sender: system_sender,
          source: resource.source
        )
      end

      private

      # TODO: When a Bot/System user model is added, use that as the sender.
      # For now, we use the first admin user as a fallback.
      def system_sender
        AccountUser.find_by(account: account, owner: true)&.user
      end
    end
  end
end
