# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.1.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class EditHandler < ApplicationService
        attr_accessor :whatsapp_channel, :account, :parsed_params, :msg, :protocol

        def initialize(whatsapp_channel:, parsed_params:)
          self.whatsapp_channel = whatsapp_channel
          self.account          = whatsapp_channel.account
          self.parsed_params    = parsed_params
          self.msg              = parsed_params[:messages]&.first || {}
          self.protocol         = msg[:protocol] || msg[:protocol_message] || {}
        end

        def call
          target_external_id = protocol[:message_id] || protocol.dig(:edited_message, :id)
          new_content = protocol.dig(:edited_message, :text, :body) || protocol.dig(:edited_message, :content) || msg.dig(:text, :body)
          return if target_external_id.blank? || new_content.blank?

          lock_key = format(::RedisUtilities::Keys::MESSAGE_MUTATION_LOCK, account_id: account.id, external_id: target_external_id)

          ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
            ShardRecord.transaction do
              target_message = account.messages.where(inbox: whatsapp_channel.inboxes).find_by(external_id: target_external_id)
              return unless target_message

              target_message.edit!(new_content)
            end
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp EditHandler error: #{e.message}")
          raise(e)
        end
      end
    end
  end
end
