# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class EventListener < ApplicationService
        attr_accessor :inbox, :message, :event,
                      :customer, :sender_id, :account,
                      :conversation, :parsed_params, :whatsapp_channel,
                       :params

        def initialize(whatsapp_channel:, params:, account: nil)
          self.whatsapp_channel = whatsapp_channel
          self.params = params
          self.parsed_params = params[:entry].try(:first).try(:[], "changes").try(:first).try(:[], "value")
          self.account = account || whatsapp_channel.account
        end

        def call
          account.with_shard do
            if parsed_params.try(:[], :statuses).present?
              process_statuses
            elsif parsed_params.try(:[], :messages).present?
              ConversationCreator.call(
                whatsapp_channel: whatsapp_channel,
                parsed_params: parsed_params,
                account: account
              )
            end
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp EventListener error: #{e.message}")
          Rails.logger.error(e.backtrace&.first(5)&.join("\n"))
        end

        private

        def process_statuses
          status_payload = parsed_params[:statuses].first
          return unless status_payload

          message_external_id = status_payload[:id]
          status = status_payload[:status]

          error_code = status_payload.dig(:errors, 0, :code)
          error_message = status_payload.dig(:errors, 0, :title)

          params = {
            external_ids: [ message_external_id ],
            error_code: error_code,
            error_message: error_message,
            channel_class: whatsapp_channel.class.name,
            channel_id: whatsapp_channel.id
          }

          Messages::StatusUpdateWorker.perform_async(account.id, status, params.as_json)
        rescue StandardError => e
          Rails.logger.error("WhatsApp EventListener status process error => #{e.message}")
        end
      end
    end
  end
end
