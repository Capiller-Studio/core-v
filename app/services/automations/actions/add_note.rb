# frozen_string_literal: true

module Automations
  module Actions
    class AddNote < BaseAction
      def call
        require_conversation!

        content = params[:content]
        raise("content is required") if content.blank?

        content = Automations::ContentRenderer.call(content: content, conversation: resource, account: account, actor: actor)

        if actor
          # Manual macro run: a regular private note authored by the agent,
          # identical to one typed in the composer's "Note" tab.
          Messages::MessageCreator.call(
            conversation: resource,
            content: content,
            sender: actor,
            visibility: "personal"
          )
        else
          # Automatic run: system activity note — visibility "personal" so customers don't see it
          resource.messages.create!(
            account: account,
            inbox: resource.inbox,
            content: content,
            visibility: :personal,
            content_type: :activity,
            sender: account,
            source: resource.source
          )
        end
      end
    end
  end
end
