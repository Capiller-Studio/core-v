# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.2.0
# Website: https://techbolic.com/

module Parser
  class InstagramMessageParser < ApplicationService
    attr_accessor :message

    def initialize(message:)
      self.message = message.with_indifferent_access
    end

    def call
      # TODO: Return a hash or maybe some object
      self
    end

    def mid
      @mid ||= message.dig("message", "mid") || edit_mid || reaction_mid || unsend_mid
    end

    def sender_id
      @sender_id ||= message.dig("sender", "id")
    end

    def recipient_id
      @recipient_id ||= message.dig("recipient", "id")
    end

    def content
      @content ||= message.dig("message_edit", "text") || message.dig("message", "text")
    end

    def attachments
      @attachments ||= message.dig("message", "attachments") || []
    end

    def sequence
      @sequence ||= message.dig("message", "seq")
    end

    def reply_to_mid
      @reply_to_mid ||= message.dig("message", "reply_to", "mid")
    end

    def timestamp
      @timestamp ||= message["timestamp"]
    end

    def delivery
      @delivery ||= message["delivery"]
    end

    def read
      @read ||= message["read"]
    end

    def read_watermark
      @read_watermark ||= read&.dig("watermark")
    end

    def delivery_watermark
      @delivery_watermark ||= delivery&.dig("watermark")
    end

    def echo?
      @echo ||= message.dig("message", "is_echo")
    end

    # Reactions
    def reaction
      @reaction ||= message["reaction"]
    end

    def reaction_mid
      @reaction_mid ||= reaction&.dig("mid")
    end

    def reaction_emoji
      @reaction_emoji ||= reaction&.dig("emoji")
    end

    def reaction_action
      @reaction_action ||= reaction&.dig("action") # "react" or "unreact"
    end

    def reaction_name
      @reaction_name ||= reaction&.dig("reaction")
    end

    # Message Edits
    def message_edit
      @message_edit ||= message["message_edit"]
    end

    def edit_mid
      @edit_mid ||= message_edit&.dig("mid")
    end

    # Message Unsends / Deletions
    def message_unsend
      @message_unsend ||= message["message_unsend"] || message["message_delete"]
    end

    def unsend_mid
      @unsend_mid ||= message_unsend&.dig("mid")
    end
  end
end
