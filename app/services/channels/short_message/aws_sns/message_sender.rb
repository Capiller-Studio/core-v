# frozen_string_literal: true

module Channels
  module ShortMessage
    module AwsSns
      class MessageSender < ApplicationService
        attr_reader :message, :channel

        def initialize(message)
          @message = message
          @channel = message.inbox.channel
        end

        def call
          return unless message.sender.is_a?(User)

          # Connect securely using AWS SDK
          client = Aws::SNS::Client.new(
            region: region,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          )

          response = client.publish(
            phone_number: message.conversation.customer.full_phone_number,
            message: message.content
          )

          message.update!(external_id: response.message_id)
        rescue Aws::SNS::Errors::ServiceError => e
          Rails.logger.error("AWS SNS failed to transmit: #{e.message}")
        end

        private

        def region
          channel.configurations["region"] || channel.configurations[:region] || "us-east-1"
        end

        def access_key_id
          channel.configurations["access_key_id"] || channel.configurations[:access_key_id]
        end

        def secret_access_key
          channel.configurations["secret_access_key"] || channel.configurations[:secret_access_key]
        end
      end
    end
  end
end
