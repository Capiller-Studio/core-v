# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module ShortMessage
    class MessageSender < ApplicationService
      attr_accessor :short_message_channel, :message

      def initialize(short_message_channel:, message:)
        self.short_message_channel = short_message_channel
        self.message               = message
      end

      def call
        return if message.content.blank?

        provider = short_message_channel.service
        sender_class = case provider
                       when "twilio"    then Channels::ShortMessage::Twilio::MessageSender
                       when "signalwire" then Channels::ShortMessage::Signalwire::MessageSender
                       when "aws_sns"    then Channels::ShortMessage::AwsSns::MessageSender
                       else
                         Rails.logger.warn "ShortMessage: Unsupported provider: #{provider}"
                         nil
                       end

        # SMS provider services use (message) as initializer
        sender_class.call(message) if sender_class
      end
    end
  end
end
