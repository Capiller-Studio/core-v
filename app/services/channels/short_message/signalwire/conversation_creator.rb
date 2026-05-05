# frozen_string_literal: true

module Channels
  module ShortMessage
    module Signalwire
      class ConversationCreator < Channels::ShortMessage::Twilio::ConversationCreator
        # Signalwire's REST API and Webhook payload schema is literally designed
        # to be 100% syntactically identical to Twilio's webhook schema (From, To, Body).
        # We can safely inherit the extraction flow natively without rewriting it.
      end
    end
  end
end
