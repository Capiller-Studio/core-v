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

        ActiveRecord::Base.transaction do
          find_or_create_customer
          find_or_create_conversation
          create_message
        end
      rescue Koala::Facebook::AuthenticationError => _e
        # TODO: Error handling
      rescue StandardError => _e
        # TODO: Error handling
      end

      private

      def find_inbox
        # TODO: Logic for finding the correct inbox. Maybe: One inbox will act as default and other inboxes will
        # receive conversations/messages based on Filters
        self.inbox = channel.primary_inbox
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
          data: {}
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
            first_name: customer_data["first_name"],
            last_name: customer_data["last_name"],
            avatar_url: customer_data["profile_pic"] || customer_data["avatar_url"],
            gender: customer_data["gender"]
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
          name: customer_data["name"] || [ customer_data["first_name"], customer_data["last_name"] ].compact.join(" "),
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
        client = Koala::Facebook::API.new(channel.access_token)
        client.get_object(sender_id)
      rescue Koala::Facebook::AuthenticationError => e
        channel.authorization_error!
        Rails.logger.error("Instagram auth error fetching customer #{sender_id}: #{e.message}")
        nil
      rescue Koala::Facebook::ClientError => e
        Rails.logger.error("Instagram client error fetching customer #{sender_id}: #{e.message}")
        nil
      rescue StandardError => e
        Rails.logger.error("Instagram error fetching customer #{sender_id}: #{e.message}")
        nil
      end
    end
  end
end
