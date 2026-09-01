# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.3.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class ConversationCreator < ApplicationService
        include Channels::Concerns::ConversationFinder

        INVALID_MESSAGE_TYPES = %w[request_welcome ephemeral unsupported].freeze

        attr_accessor :inbox, :message, :parsed_params,
                      :whatsapp_channel, :customer, :sender_id, :account,
                      :conversation, :message_type

        def initialize(whatsapp_channel:, parsed_params:, account: nil)
          self.parsed_params    = parsed_params
          self.whatsapp_channel = whatsapp_channel
          self.account          = account || whatsapp_channel.account
          self.message_type     = find_message_type
        end

        def call
          return if invalid_message_type?(message_type)

          account.with_shard do
            find_inbox

            if message_type == "reaction"
              ReactionHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params)
              return
            elsif message_type == "protocol"
              process_protocol
              return
            end

            return if find_existing_message(parsed_params[:messages].first[:id]) || message_creation_locked?

            lock_message_creation

            lock_key = format(
              ::RedisUtilities::Keys::WHATSAPP_MESSAGE_CREATION_LOCK,
              receiver_id: whatsapp_channel.phone_number_id,
              sender_id: parsed_params[:messages].first[:from]
            )

            ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
              # Double check after acquiring lock to ensure we don't process if another thread just finished
              return if find_existing_message(parsed_params[:messages].first[:id])

              ShardRecord.transaction do
                find_or_create_customer
                find_or_create_conversation
                create_message
              end
            end

            unlock_message_creation
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp ConversationCreator error: #{e.message}")
          Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
          SystemLog.log_event(
            SystemLogs::EventKeys::WEBHOOK_WHATSAPP_ERROR,
            level: :error,
            account: account,
            message: e.message,
            payload: { error_class: e.class.name, phone_number_id: whatsapp_channel.try(:phone_number_id) }
          )
        end

        private

        def process_protocol
          msg = parsed_params[:messages].first
          protocol = msg[:protocol] || msg[:protocol_message] || {}

          if protocol[:type] == "edited_message" || protocol[:edited_message].present?
            EditHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params)
          elsif protocol[:type] == "revocation"
            UnsendHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: parsed_params)
          end
        end

        def find_inbox
          self.inbox = whatsapp_channel.primary_inbox
        end

        def find_existing_message(external_id)
          return nil if external_id.blank?

          account.messages.where(inbox: whatsapp_channel.inboxes).find_by(external_id: external_id)
        end

        def invalid_message_type?(message_type)
          INVALID_MESSAGE_TYPES.include?(message_type)
        end

        def message_creation_locked?
          ::RedisUtilities::Helpers.get(message_creation_lock_key)
        end

        def lock_message_creation
          return if parsed_params.try(:[], :messages).blank?

          ::RedisUtilities::Helpers.set(message_creation_lock_key, 1, expiry: 10.minutes)
        end

        def unlock_message_creation
          ::RedisUtilities::Helpers.delete(message_creation_lock_key)
        end

        def message_creation_lock_key
          @message_creation_lock_key ||=
          format(
            ::RedisUtilities::Keys::MESSAGE_CREATION_LOCK,
            account_id: account.id,
            id: parsed_params[:messages].first[:id]
          )
        end

        def find_message_type
          self.message_type ||= parsed_params[:messages].first[:type]
        end

        def find_or_create_customer
          create_customer
        end

        def create_customer
          customer_data = parsed_params[:contacts]&.first || {}

          self.customer = Customers::CustomerCreator.call(
            account: account,
            inbox: inbox,
            external_id: customer_data["wa_id"] || parsed_params[:messages].first[:from],
            full_phone_number: "+#{parsed_params[:messages].first[:from]}",
            params: {
              name: customer_data.dig(:profile, :name),
              locale: ::Utilities::LocaleParser.parse(customer_data["locale"] || customer_data["language"] || customer_data.dig(:profile, :locale))
            }
          )

          create_native_identity(customer_data)
        end

        def create_native_identity(customer_data)
          return if customer_data.blank?
          return if account.identities.exists?(customer: customer, identity_type: :whatsapp)

          account.identities.create!(
            customer: customer,
            identity_type: :whatsapp,
            identifier: customer_data["wa_id"] || parsed_params[:messages].first[:from],
            name: customer_data.dig(:profile, :name),
            raw_response: customer_data
          )
        rescue StandardError => e
          Rails.logger.error("Failed to create native whatsapp identity: #{e.message}")
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
            source: :whatsapp,
            data: {},
            locale: customer.locale
          )
        end

        def find_or_create_conversation_member
          conversation.conversation_members.find_or_create_by!(
            conversation: conversation,
            member: customer,
            account: account
          )
        end

        def create_message
          MessageCreator.call(
            account: account,
            inbox: inbox,
            conversation: conversation,
            parsed_message: parsed_params,
            sender: customer,
            whatsapp_channel: whatsapp_channel,
            message_type: message_type
          )
        end
      end
    end
  end
end
