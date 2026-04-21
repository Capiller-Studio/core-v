# frozen_string_literal: true

module Channels
  module ShortMessage
    module AwsSns
      class MessageCreator < ApplicationService
        attr_accessor :parsed_message, :account, :inbox, :sender,
                      :conversation, :message, :short_message_channel,
                      :aws_message

        def initialize(parsed_message:, account:, inbox:, sender:, conversation:, short_message_channel:)
          self.parsed_message        = parsed_message
          self.aws_message           = JSON.parse(parsed_message["Message"] || "{}") rescue {}
          self.inbox                 = inbox
          self.sender                = sender
          self.account               = account
          self.conversation          = conversation
          self.short_message_channel = short_message_channel
        end

        def call
          ActiveRecord::Base.transaction do
            unless find_message
              create_message
              # AWS SNS Inbound natively strips MMS natively (requires Pinpoint or external routing natively to S3)
              # So we don't process massive media arrays natively natively here.
            end
          end
          message
        end

        private

        def create_message
          self.message = conversation.messages.create!(
            account: account,
            sender: sender,
            content: aws_message["messageBody"],
            inbox: inbox,
            external_id: parsed_message["MessageId"], # Use the outer payload SNS Notification ID natively 
            data: {}
          )
        end

        def find_message
          self.message = conversation.messages.find_by(external_id: parsed_message["MessageId"])
        end
      end
    end
  end
end
