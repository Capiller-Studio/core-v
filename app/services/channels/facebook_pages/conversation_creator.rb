# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class ConversationCreator < ApplicationService
      include Channels::Concerns::ConversationFinder

      attr_accessor :inbox, :message, :parsed_message, :event,
                    :facebook_page_channel, :customer, :sender_id, :account,
                    :conversation

      def initialize(facebook_page_channel:, parsed_message:, event: :message, account: nil)
        self.parsed_message        = parsed_message
        self.facebook_page_channel = facebook_page_channel
        self.event                 = event
        self.account               = account || facebook_page_channel.account
        self.sender_id             = echo? ? parsed_message.recipient_id : parsed_message.sender_id
      end

      def echo?
        parsed_message.echo? || (facebook_page_channel.page_identifier.present? && parsed_message.sender_id.to_s == facebook_page_channel.page_identifier.to_s)
      end

      def call
        find_inbox

        ShardRecord.transaction do
          find_or_create_customer
          find_or_create_conversation
          create_message
        end
      rescue Koala::Facebook::AuthenticationError => e
        SystemLog.log_event("webhook.facebook.auth_error", level: :error, account: account, message: e.message)
        raise(e)
      rescue StandardError => e
        SystemLog.log_event(
          "webhook.facebook.error", 
          level: :error, 
          account: account, 
          message: e.message, 
          payload: { error_class: e.class.name, backtrace: e.backtrace&.first(5) }
        )
        raise(e)
      end

      private

      def find_inbox
        self.inbox = facebook_page_channel.primary_inbox
      end

      def find_or_create_conversation
        find_conversation || create_conversation
        find_or_create_conversation_member
      end

      def find_conversation
        self.conversation = find_or_reopen_conversation(customer, inbox, account)
      end

      def create_conversation
        # TODO: Fix placeholder identifier
        self.conversation = account.conversations.create!(
          inbox:,
          source: :facebook_message,
          data: {},
          locale: customer.locale
        )
      end

      def find_or_create_customer
        create_customer
      end

      def create_customer
        customer_data = fetch_customer_details || {}

        self.customer = Customers::CustomerCreator.call(
          account:,
          inbox:,
          external_id: sender_id,
          email: customer_data["email"],
          params: {
            first_name: customer_data["first_name"],
            last_name: customer_data["last_name"],
            avatar_url: customer_data["profile_pic"],
            gender: customer_data["gender"],
            locale: ::Utilities::LocaleParser.parse(customer_data["locale"])
          }
        )

        create_native_identity(customer_data)
      end

      def create_native_identity(customer_data)
        return if customer_data.blank?
        return if account.identities.exists?(customer: customer, identity_type: :facebook)

        account.identities.create!(
          customer: customer,
          identity_type: :facebook,
          identifier: sender_id,
          first_name: customer_data["first_name"],
          last_name: customer_data["last_name"],
          name: customer_data["name"] || [ customer_data["first_name"], customer_data["last_name"] ].compact.join(" "),
          raw_response: customer_data,
          custom_attributes: {
            "Gender" => customer_data["gender"],
            "Locale" => customer_data["locale"],
            "Timezone" => customer_data["timezone"],
            "Profile Picture" => customer_data["profile_pic"]
          }.compact
        )
      rescue StandardError => e
        Rails.logger.error("Failed to create native facebook identity: #{e.message}")
      end

      def find_or_create_conversation_member
        conversation.conversation_members.find_or_create_by!(conversation:, member: customer, account:)
      end

      def create_message
        MessageCreator.call(
          account:,
          inbox:,
          conversation:,
          parsed_message:,
          sender: echo? ? account : customer,
          facebook_page_channel:
        )
      end

      def fetch_customer_details
        client = Koala::Facebook::API.new(facebook_page_channel.access_token)
        client.get_object(sender_id)
      rescue Koala::Facebook::AuthenticationError => e
        facebook_page_channel.authorization_error!
        Rails.logger.error("[FacebookPages::ConversationCreator] Auth error fetching customer #{sender_id}: #{e.message}")
        nil
      rescue Koala::Facebook::ClientError => e
        Rails.logger.warn("[FacebookPages::ConversationCreator] Client error fetching customer #{sender_id}: #{e.message}")
        nil
      rescue StandardError => e
        Rails.logger.error("[FacebookPages::ConversationCreator] Unexpected error fetching customer #{sender_id}: #{e.message}")
        nil
      end
    end
  end
end
