# frozen_string_literal: true

module Automations
  module Actions
    class SendMessage < BaseAction
      def call
        require_conversation!

        content = params[:content]
        raise("content is required") if content.blank?

        visibility = params.fetch(:visibility, "global")

        # Send as a system/bot message using the Account as the sender
        message = resource.messages.create!(
          account: account,
          inbox: resource.inbox,
          content: content,
          visibility: visibility,
          content_type: :text,
          sender: account,
          source: resource.source
        )

        # Dispatch the message using the core delivery worker
        Messages::DeliveryWorker.perform_async(message.account_id, message.id)
      end

    end
  end
end
