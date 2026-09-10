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
                      :whatsapp_channel, :customer, :account,
                      :conversation

        def initialize(whatsapp_channel:, parsed_params:, account: nil)
          self.parsed_params    = parsed_params
          self.whatsapp_channel = whatsapp_channel
          self.account          = account || whatsapp_channel.account
        end

        def call
          return if raw_messages.blank?

          account.with_shard do
            find_inbox

            raw_messages.each do |msg|
              process_message(msg)
            end
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp ConversationCreator error: #{e.message}")
          Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
          SystemLog.log_event(
            SystemLogs::EventKeys::WEBHOOK_WHATSAPP_ERROR,
            level: :error,
            account: account,
            message: e.message,
            payload: { error_class: e.class.name, phone_number_id: whatsapp_channel&.phone_number_id }
          )
        end

        private

        def raw_messages
          @raw_messages ||= (
            Array(parsed_params[:messages]) +
            Array(parsed_params["messages"]) +
            Array(parsed_params[:message_echoes]) +
            Array(parsed_params["message_echoes"])
          ).compact.uniq
        end

        def process_message(msg)
          msg_type = message_type_for(msg)
          return if invalid_message_type?(msg_type)

          msg_params = parsed_params_for(msg)

          if msg_type == "reaction"
            ReactionHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: msg_params)
            return
          elsif msg_type == "protocol"
            process_protocol(msg, msg_params)
            return
          end

          msg_id = message_id_for(msg)
          return if msg_id.present? && (find_existing_message(msg_id) || message_creation_locked?(msg_id))

          lock_message_creation(msg_id)

          sender_key = customer_phone_for(msg) || (msg[:from] || msg["from"])
          lock_key = format(
            ::RedisUtilities::Keys::WHATSAPP_MESSAGE_CREATION_LOCK,
            receiver_id: whatsapp_channel.phone_number_id,
            sender_id: sender_key
          )

          ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
            return if msg_id.present? && find_existing_message(msg_id)

            ShardRecord.transaction do
              self.customer = find_or_create_customer_for(msg)
              find_or_create_conversation
              create_message_for(msg, msg_type, msg_params)
            end
          end

          unlock_message_creation(msg_id)
        end

        def process_protocol(msg, msg_params)
          protocol = msg[:protocol] || msg["protocol"] || msg[:protocol_message] || msg["protocol_message"] || {}

          if protocol[:type] == "edited_message" || protocol["type"] == "edited_message" || protocol[:edited_message].present? || protocol["edited_message"].present?
            EditHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: msg_params)
          elsif protocol[:type] == "revocation" || protocol["type"] == "revocation"
            UnsendHandler.call(whatsapp_channel: whatsapp_channel, parsed_params: msg_params)
          end
        end

        def find_inbox
          self.inbox = whatsapp_channel.primary_inbox
        end

        def find_existing_message(external_id)
          return nil if external_id.blank?

          account.messages.where(inbox: whatsapp_channel.inboxes).find_by(external_id: external_id.to_s)
        end

        def invalid_message_type?(message_type)
          message_type.blank? || INVALID_MESSAGE_TYPES.include?(message_type)
        end

        def message_type_for(msg)
          msg&.[](:type) || msg&.[]("type")
        end

        def message_id_for(msg)
          msg&.[](:id) || msg&.[]("id")
        end

        def message_creation_locked?(msg_id)
          return false if msg_id.blank?

          ::RedisUtilities::Helpers.get(message_creation_lock_key(msg_id))
        end

        def lock_message_creation(msg_id)
          return if msg_id.blank?

          ::RedisUtilities::Helpers.set(message_creation_lock_key(msg_id), 1, expiry: 10.minutes)
        end

        def unlock_message_creation(msg_id)
          return if msg_id.blank?

          ::RedisUtilities::Helpers.delete(message_creation_lock_key(msg_id))
        end

        def message_creation_lock_key(msg_id)
          format(
            ::RedisUtilities::Keys::MESSAGE_CREATION_LOCK,
            account_id: account.id,
            id: msg_id
          )
        end

        def echo?(msg)
          return true if is_echo_message?(msg)

          from = (msg[:from] || msg["from"]).to_s.gsub(/\D/, "")
          return false if from.blank?

          (whatsapp_channel.full_phone_number.present? && from == whatsapp_channel.full_phone_number.to_s.gsub(/\D/, "")) ||
            (whatsapp_channel.phone_number.present? && from == whatsapp_channel.phone_number.to_s.gsub(/\D/, "")) ||
            (metadata_phone.present? && from == metadata_phone.to_s.gsub(/\D/, ""))
        end

        def is_echo_message?(msg)
          msg[:is_echo] == true || msg["is_echo"] == true ||
            Array(parsed_params[:message_echoes]).include?(msg) ||
            Array(parsed_params["message_echoes"]).include?(msg)
        end

        def metadata_phone
          parsed_params.dig(:metadata, :display_phone_number) || parsed_params.dig("metadata", "display_phone_number")
        end

        def customer_phone_for(msg)
          return nil if msg.blank?

          if echo?(msg)
            msg[:to] || msg["to"] || msg[:recipient_id] || msg["recipient_id"]
          else
            msg[:from] || msg["from"]
          end
        end

        def parsed_params_for(msg)
          if is_echo_message?(msg)
            parsed_params.merge(message_echoes: [msg])
          else
            parsed_params.merge(messages: [msg])
          end
        end

        def find_or_create_customer_for(msg)
          customer_data = parsed_params[:contacts]&.first || parsed_params["contacts"]&.first || {}
          phone = customer_phone_for(msg).to_s.gsub(/\D/, "")
          is_echo = echo?(msg)
          wa_id = customer_data["wa_id"] || customer_data[:wa_id]

          resolved_customer = Customers::CustomerCreator.call(
            account: account,
            inbox: inbox,
            external_id: (wa_id.presence unless is_echo) || phone,
            full_phone_number: phone.present? ? "+#{phone}" : nil,
            params: {
              name: (customer_data.dig(:profile, :name) || customer_data.dig("profile", "name") unless is_echo),
              locale: ::Utilities::LocaleParser.parse(customer_data["locale"] || customer_data["language"] || customer_data.dig(:profile, :locale))
            }
          )

          create_native_identity(customer_data, resolved_customer, phone) unless is_echo
          resolved_customer
        end

        def create_native_identity(customer_data, resolved_customer, phone)
          return if customer_data.blank? || resolved_customer.blank?
          return if account.identities.exists?(customer: resolved_customer, identity_type: :whatsapp)

          wa_id = customer_data["wa_id"] || customer_data[:wa_id]
          account.identities.create!(
            customer: resolved_customer,
            identity_type: :whatsapp,
            identifier: wa_id || phone,
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

        def create_message_for(msg, msg_type, msg_params)
          MessageCreator.call(
            account: account,
            inbox: inbox,
            conversation: conversation,
            parsed_message: msg_params,
            sender: echo?(msg) ? account : customer,
            whatsapp_channel: whatsapp_channel,
            message_type: msg_type
          )
        end
      end
    end
  end
end
