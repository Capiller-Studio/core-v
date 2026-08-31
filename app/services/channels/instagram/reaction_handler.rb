# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class ReactionHandler < ApplicationService
      attr_accessor :channel, :account, :parsed_message, :sender_id, :mid

      def initialize(channel:, parsed_message:)
        self.channel        = channel
        self.account        = channel.account
        self.parsed_message = parsed_message
        self.sender_id      = parsed_message.sender_id
        self.mid            = parsed_message.reaction_mid
      end

      def call
        return if mid.blank? || sender_id.blank?

        lock_key = format(::RedisUtilities::Keys::MESSAGE_MUTATION_LOCK, account_id: account.id, external_id: mid)

        ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
          ShardRecord.transaction do
            message = account.messages.where(inbox: channel.inboxes).find_by(external_id: mid)
            return unless message

            sender = find_sender
            return unless sender

            action = parsed_message.reaction_action.to_s.downcase == "unreact" ? :unreact : :react

            Messages::ReactionManager.call(
              message: message,
              sender: sender,
              emoji: parsed_message.reaction_emoji,
              action: action,
              reaction_name: parsed_message.reaction_name,
              external_id: mid
            )
          end
        end
      rescue StandardError => e
        Rails.logger.error("Instagram ReactionHandler error: #{e.message}")
        raise(e)
      end

      private

      def echo?
        (parsed_message.respond_to?(:echo?) && parsed_message.echo?) || sender_id.to_s == channel.instagram_id.to_s
      end

      def find_sender
        return account if echo?

        find_or_create_customer
      end

      def find_customer
        identity = account.identities.find_by(identity_type: :instagram, identifier: sender_id.to_s)
        return identity.customer if identity&.customer

        inbox = channel.primary_inbox || channel.inboxes.first
        return nil unless inbox

        inbox.customer_inboxes.find_by(external_id: sender_id.to_s)&.customer
      end

      def find_or_create_customer
        customer = find_customer
        return customer if customer

        inbox = channel.primary_inbox || channel.inboxes.first
        return nil unless inbox

        customer_data = fetch_customer_details || {}
        customer = Customers::CustomerCreator.call(
          account: account,
          inbox: inbox,
          external_id: sender_id.to_s,
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

        create_identity(customer, customer_data) if customer.present?
        customer
      end

      def create_identity(customer, customer_data)
        return if account.identities.exists?(customer: customer, identity_type: :instagram)

        account.identities.create!(
          customer: customer,
          identity_type: :instagram,
          identifier: sender_id.to_s,
          first_name: customer_data["first_name"],
          last_name: customer_data["last_name"],
          name: customer_data["name"] || [ customer_data["first_name"], customer_data["last_name"] ].compact.join(" ").presence || customer_data["username"],
          raw_response: customer_data,
          custom_attributes: {}
        )
      rescue StandardError => e
        Rails.logger.error("Instagram ReactionHandler identity error: #{e.message}")
      end

      def fetch_customer_details
        response = HTTParty.get(
          "https://graph.instagram.com/#{Channels::Instagram::OauthService::API_VERSION}/#{sender_id}",
          query: {
            fields: "id,username,name,profile_picture_url",
            access_token: channel.access_token
          }
        )

        if response.success?
          JSON.parse(response.body)
        else
          error_data = response.parsed_response&.dig("error") || {}
          error_code = error_data["code"].to_i

          if response.code == 401 || error_code == 190 || error_data["message"].to_s.include?("Error validating access token")
            channel.authorization_error!
          end
          nil
        end
      rescue StandardError => e
        Rails.logger.error("Instagram ReactionHandler fetch customer error: #{e.message}")
        nil
      end
    end
  end
end
