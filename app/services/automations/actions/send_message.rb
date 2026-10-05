# frozen_string_literal: true

module Automations
  module Actions
    class SendMessage < BaseAction
      def call
        require_conversation!

        content = params[:content]
        raise("content is required") if content.blank?

        visibility = params.fetch(:visibility, "global").to_s == "personal" ? "personal" : "global"

        # Manual macro runs send as the agent who triggered them; automatic
        # automation runs send as the account (system/bot sender).
        # MessageCreator persists the message and enqueues channel delivery for global messages.
        Messages::MessageCreator.call(
          conversation: resource,
          content: rendered(content),
          sender: actor || account,
          visibility: visibility
        )
      end

      private

      def rendered(content)
        Automations::ContentRenderer.call(content: content, conversation: resource, account: account, actor: actor)
      end
    end
  end
end
