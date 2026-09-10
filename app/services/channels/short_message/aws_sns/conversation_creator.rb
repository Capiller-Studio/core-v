# frozen_string_literal: true

module Channels
  module ShortMessage
    module AwsSns
      class ConversationCreator < ApplicationService
        include Channels::Concerns::ConversationFinder

        # NOTE: AWS routes inbound SMS via SNS Topics (HTTP/S subscriptions) natively.
        # This payload arrives completely differently than Twilio (usually embedded inside a generic SNS Notification JSON).
        # We must actively parse the "Message" string out of the payload, then extract
        # originationNumber and destinationNumber cleanly here natively.

        attr_accessor :inbox, :message, :parsed_params,
                      :short_message_channel, :customer, :sender_id, :account,
                      :conversation

        def initialize(short_message_channel:, parsed_params:, account: nil)
          self.parsed_params         = parsed_params
          self.short_message_channel = short_message_channel
          self.account               = account || short_message_channel.account

          # AWS nested extraction mapping natively
          aws_message = JSON.parse(parsed_params["Message"] || "{}") rescue {}
          origination_number = aws_message["originationNumber"]
          destination_number = aws_message["destinationNumber"]

          origination_clean = origination_number.to_s.gsub(/\D/, "")

          @is_echo = origination_clean.present? && (
            (short_message_channel.phone_number.present? && origination_clean == short_message_channel.phone_number.to_s.gsub(/\D/, "")) ||
            (short_message_channel.full_phone_number.present? && origination_clean == short_message_channel.full_phone_number.to_s.gsub(/\D/, ""))
          )

          self.sender_id = @is_echo ? destination_number : origination_number
        end

        def echo?
          @is_echo
        end

        def call
          return if sender_id.blank?

          find_inbox

          message_id = parsed_params["MessageId"]
          return if find_existing_message(message_id) || message_creation_locked?(message_id)

          lock_message_creation(message_id)

          begin
            ShardRecord.transaction do
              find_or_create_customer
              find_or_create_conversation
              create_message
            end
          ensure
            unlock_message_creation(message_id)
          end
        rescue StandardError => _e
          Rails.logger.error("AWS SNS Parsing Failed: #{_e.message}")
        end

        private

        def find_inbox
          self.inbox = short_message_channel.primary_inbox
        end

        def find_or_create_customer
          self.customer = Customers::CustomerCreator.call(
            account: account,
            inbox: inbox,
            external_id: sender_id,
            full_phone_number: sender_id,
            params: {
              name: sender_id # AWS doesn't provide names natively inside inbound SMS strings
            }
          )
        end

        def find_or_create_conversation
          find_conversation || create_conversation
          find_or_create_conversation_member
        end

        def find_conversation
          self.conversation = find_or_reopen_conversation(customer, inbox, account)
        end

        def create_conversation
          self.conversation = account.conversations.create!(
            inbox: inbox,
            source: :sms,
            data: {}
          )
        end

        def find_or_create_conversation_member
          conversation.conversation_members.find_or_create_by!(conversation: conversation, member: customer, account: account)
        end

        def create_message
          MessageCreator.call(
            account: account,
            inbox: inbox,
            conversation: conversation,
            parsed_message: parsed_params,
            sender: echo? ? account : customer,
            short_message_channel: short_message_channel
          )
        end

        def find_existing_message(external_id)
          return false unless external_id
          account.messages.exists?(external_id: external_id)
        end

        def message_creation_locked?(external_id)
          ::RedisUtilities::Helpers.get(message_creation_lock_key(external_id)).present?
        end

        def lock_message_creation(external_id)
          ::RedisUtilities::Helpers.set(message_creation_lock_key(external_id), 1, expiry: 10.minutes)
        end

        def unlock_message_creation(external_id)
          ::RedisUtilities::Helpers.delete(message_creation_lock_key(external_id))
        end

        def message_creation_lock_key(external_id)
          format(
            ::RedisUtilities::Keys::MESSAGE_CREATION_LOCK,
            account_id: account.id,
            id: external_id
          )
        end
      end
    end
  end
end
