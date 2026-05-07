# frozen_string_literal: true

module Channels
  module ShortMessage
    module Twilio
      class MessageSender < ApplicationService
        attr_reader :message, :channel

        def initialize(message)
          @message = message
          @channel = message.inbox.channel
        end

        def call
          return unless message.sender.is_a?(User)

          client = ::Twilio::REST::Client.new(account_sid, auth_token)

          # Send via official SDK natively
          response = client.messages.create(
            from: channel.phone_number,
            to: message.conversation.customer.full_phone_number,
            body: message.content
          )

          message.update!(external_id: response.sid, status: :delivered)
        rescue ::Twilio::REST::TwilioError => e
          Rails.logger.error("Twilio SMS failed to send: #{e.message}")
          message.update!(status: :failed)
          raise e
        end

        private

        def account_sid
          channel.configurations["account_sid"] || channel.configurations[:account_sid]
        end

        def auth_token
          channel.configurations["auth_token"] || channel.configurations[:auth_token]
        end
      end
    end
  end
end
