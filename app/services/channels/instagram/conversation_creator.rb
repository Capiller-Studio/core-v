# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class ConversationCreator < ApplicationService
      include Channels::Concerns::ConversationFinder

      attr_accessor :inbox, :message, :parsed_message,
                    :channel, :customer, :sender_id, :account,
                    :conversation

      def initialize(channel:, parsed_message:, account: nil)
        self.parsed_message = parsed_message
        self.channel        = channel
        # TODO: Ignore system sent messages
        self.sender_id = parsed_message.echo? ? parsed_message.recipient_id : parsed_message.sender_id
        self.account   = account || channel.account
      end

      def call
        find_inbox

        ShardRecord.transaction do
          find_or_create_customer
          find_or_create_conversation
          create_message
        end
      rescue StandardError => e
        SystemLog.log_event(
          "webhook.instagram.error", 
          level: :error, 
          account: account, 
          message: e.message, 
          payload: { error_class: e.class.name, backtrace: e.backtrace&.first(5) }
        )
        raise(e)
      end

      private

      def find_inbox
        # Use primary inbox or fallback to first associated inbox
        self.inbox = channel.primary_inbox || channel.inboxes.first
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
          source: :instagram_direct_message,
          data: {},
          locale: customer.locale
        )
      end

      def find_or_create_customer
        create_customer
      end

      # TODO: Add identifers: { instagram: customer_data["username"] }
      def create_customer
        customer_data = fetch_customer_details || {}
        self.customer = Customers::CustomerCreator.call(
          account:,
          inbox:,
          external_id: sender_id,
          email: customer_data["email"],
          params: {
            name: customer_data["name"] || customer_data["username"],
            first_name: customer_data["first_name"],
            last_name: customer_data["last_name"],
            avatar_url: customer_data["profile_pic"] || customer_data["profile_picture_url"] || customer_data["avatar_url"],
            gender: customer_data["gender"],
            locale: ::Utilities::LocaleParser.parse(customer_data["locale"])
          }
        )
        create_identity(customer_data) if customer.present?
      end

      def create_identity(customer_data)
        return if account.identities.exists?(customer: customer, identity_type: :instagram)

        account.identities.create!(
          customer: customer,
          identity_type: :instagram,
          identifier: sender_id,
          first_name: customer_data["first_name"],
          last_name: customer_data["last_name"],
          name: customer_data["name"] || [ customer_data["first_name"], customer_data["last_name"] ].compact.join(" ").presence || customer_data["username"],
          raw_response: customer_data,
          custom_attributes: {}
        )
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
          sender: customer,
          instagram_channel: channel
        )
      end

      def fetch_customer_details
        response = HTTParty.get(
          "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/#{sender_id}",
          query: {
            fields: "id,username,name,profile_pic",
            access_token: channel.access_token
          }
        )

        if response.success?
          JSON.parse(response.body)
        else
          error_data = response.parsed_response&.dig("error") || {}
          error_code = error_data["code"].to_i

          # Code 190: Invalid OAuth 2.0 Access Token (expired or revoked)
          if response.code == 401 || error_code == 190 || error_data["message"].to_s.include?("Error validating access token")
            channel.authorization_error!
            Rails.logger.error("Instagram auth error fetching customer #{sender_id}: #{response.body}")
          else
            Rails.logger.error("Instagram error fetching customer #{sender_id}: #{response.body}")
          end
          nil
        end
      rescue StandardError => e
        Rails.logger.error("Instagram error fetching customer #{sender_id}: #{e.message}")
        if e.to_s.include?("The session has been invalidated") || e.to_s.include?("Error validating access token")
          channel.authorization_error!
        end
        nil
      end
    end
  end
end
