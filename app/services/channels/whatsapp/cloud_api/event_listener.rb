# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.1.0
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
          self.account = account || whatsapp_channel.account

          entry = (params[:entry] || params["entry"])&.first
          change = (entry.is_a?(Hash) ? (entry[:changes] || entry["changes"]) : nil)&.first
          raw_value = change.is_a?(Hash) ? (change[:value] || change["value"]) : nil
          self.parsed_params = raw_value.is_a?(Hash) ? raw_value.with_indifferent_access : {}.with_indifferent_access
        end

        def call
          account.with_shard do
            if parsed_params[:statuses].present?
              process_statuses
            elsif parsed_params[:messages].present?
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
          Array(parsed_params[:statuses]).each do |status_payload|
            next unless status_payload.is_a?(Hash)

            message_external_id = status_payload[:id]
            status = status_payload[:status]
            next if message_external_id.blank? || status.blank?

            error_code = status_payload.dig(:errors, 0, :code)
            error_message = status_payload.dig(:errors, 0, :title).presence || status_payload.dig(:errors, 0, :message)

            worker_params = {
              external_ids: [ message_external_id ],
              error_code: error_code,
              error_message: error_message,
              channel_class: whatsapp_channel.class.name,
              channel_id: whatsapp_channel.id
            }

            Messages::StatusUpdateWorker.perform_async(account.id, status.to_s, worker_params.as_json)
          end
        rescue StandardError => e
          Rails.logger.error("WhatsApp EventListener status process error => #{e.message}")
        end
      end
    end
  end
end
