# frozen_string_literal: true

module Channels
  module ShortMessage
    module Signalwire
      class MessageSender < ApplicationService
        attr_reader :message, :channel

        def initialize(message)
          @message = message
          @channel = message.inbox.channel
        end

        def call
          return unless message.sender.is_a?(User)

          # Signalwire expects project ID, Auth token, and Space URL natively
          client = ::Signalwire::REST::Client.new(project, token, signalwire_space_url: space_url)

          response = client.messages.create(
            from: channel.phone_number,
            to: message.conversation.customer.full_phone_number,
            body: message.content
          )

          message.update!(external_id: response.sid)
        rescue StandardError => e
          Rails.logger.error("Signalwire SMS failed to send: #{e.message}")
        end

        private

        def project
          channel.configurations["project"] || channel.configurations[:project]
        end

        def token
          channel.configurations["token"] || channel.configurations[:token]
        end

        def space_url
          channel.configurations["space_url"] || channel.configurations[:space_url]
        end
      end
    end
  end
end
