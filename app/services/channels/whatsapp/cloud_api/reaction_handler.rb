# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class ReactionHandler < ApplicationService
        attr_accessor :whatsapp_channel, :account, :parsed_params, :msg, :reaction

        def initialize(whatsapp_channel:, parsed_params:)
          self.whatsapp_channel = whatsapp_channel
          self.account          = whatsapp_channel.account
          self.parsed_params    = parsed_params
          self.msg              = parsed_params[:messages]&.first || {}
          self.reaction         = msg[:reaction] || {}
        end

        def call
          target_external_id = reaction[:message_id]
          return if target_external_id.blank?

          lock_key = format(::RedisUtilities::Keys::MESSAGE_MUTATION_LOCK, account_id: account.id, external_id: target_external_id)

          ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
            ShardRecord.transaction do
              target_message = account.messages.where(inbox: whatsapp_channel.inboxes).find_by(external_id: target_external_id)
              return unless target_message

              sender = find_sender
              return unless sender

              emoji = reaction[:emoji]
              action = emoji.present? ? :react : :unreact

              Messages::ReactionManager.call(
                message: target_message,
                sender: sender,
                emoji: emoji,
                action: action,
                external_id: msg[:id]
              )
            end
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp ReactionHandler error: #{e.message}")
          raise(e)
        end

        private

        def sender_id
          msg[:from]
        end

        def echo?
          return false if sender_id.blank?

          whatsapp_channel.full_phone_number.present? &&
            sender_id.to_s.gsub(/\D/, "") == whatsapp_channel.full_phone_number.to_s.gsub(/\D/, "")
        end

        def find_sender
          return account if echo?

          find_or_create_customer
        end

        def find_customer
          return nil if sender_id.blank?

          identity = account.identities.find_by(identity_type: :whatsapp, identifier: sender_id.to_s)
          return identity.customer if identity&.customer

          inbox = whatsapp_channel.primary_inbox || whatsapp_channel.inboxes.first
          return nil unless inbox

          inbox.customer_inboxes.find_by(external_id: sender_id.to_s)&.customer
        end

        def find_or_create_customer
          customer = find_customer
          return customer if customer

          inbox = whatsapp_channel.primary_inbox || whatsapp_channel.inboxes.first
          return nil unless inbox

          customer_data = parsed_params[:contacts]&.first || {}

          customer = Customers::CustomerCreator.call(
            account: account,
            inbox: inbox,
            external_id: customer_data["wa_id"] || sender_id,
            full_phone_number: "+#{sender_id}",
            params: {
              name: customer_data.dig(:profile, :name),
              locale: ::Utilities::LocaleParser.parse(customer_data["locale"] || customer_data["language"] || customer_data.dig(:profile, :locale))
            }
          )

          create_native_identity(customer, customer_data) if customer.present?
          customer
        end

        def create_native_identity(customer, customer_data)
          return if customer_data.blank?
          return if account.identities.exists?(customer: customer, identity_type: :whatsapp)

          account.identities.create!(
            customer: customer,
            identity_type: :whatsapp,
            identifier: customer_data["wa_id"] || sender_id,
            name: customer_data.dig(:profile, :name),
            raw_response: customer_data
          )
        rescue StandardError => e
          Rails.logger.error("Failed to create native whatsapp identity: #{e.message}")
        end
      end
    end
  end
end
