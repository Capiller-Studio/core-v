# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.3.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class EventListener < ApplicationService
      attr_accessor :instagram_channel, :payload, :entries

      SUPPORTED_EVENTS = %i[message delivery read reaction message_edit message_delete message_unsend].freeze

      def initialize(instagram_channel:, payload:)
        self.instagram_channel = instagram_channel
        self.payload = payload.with_indifferent_access
        self.entries = self.payload[:entry]
      end

      def call
        return if entries.blank?

        instagram_channel.account.with_shard do
          entries.each do |entry|
            (entry[:messaging].presence || entry[:standby] || []).each do |raw_message|
              event = find_event(raw_message)
              next if event.blank?

              process_event(entry, raw_message, event)
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("Instagram EventListener error: #{e.message}")
        raise(e)
      end

      private

      def find_event(raw_message)
        (SUPPORTED_EVENTS & raw_message.keys.map(&:to_sym)).first
      end

      def process_event(entry, raw_message, event)
        parsed_message = Parser::InstagramMessageParser.new(message: raw_message)

        case event
        when :message
          ::RedisUtilities::MutexHelpers.with_lock(lock_key(entry, parsed_message)) do
            ConversationCreator.call(
              channel: instagram_channel,
              parsed_message: parsed_message
            )
          end
        when :read, :delivery
          process_statuses(parsed_message, event)
        when :reaction
          ReactionHandler.call(channel: instagram_channel, parsed_message: parsed_message)
        when :message_edit
          EditHandler.call(channel: instagram_channel, parsed_message: parsed_message)
        when :message_delete, :message_unsend
          UnsendHandler.call(channel: instagram_channel, parsed_message: parsed_message)
        end
      end

      def process_statuses(parsed_message, event)
        watermark = event == :read ? parsed_message.read_watermark : parsed_message.delivery_watermark
        message_external_ids = parsed_message.message&.dig(:mids) || []
        
        if event == :read && parsed_message.read&.dig("mid").present?
          message_external_ids << parsed_message.read["mid"]
        end

        return if watermark.blank? && message_external_ids.blank?

        status = event == :read ? "read" : "delivered"

        params = {
          external_ids: message_external_ids,
          watermark: watermark,
          customer_external_id: parsed_message.sender_id,
          channel_class: instagram_channel.class.name,
          channel_id: instagram_channel.id
        }

        Messages::StatusUpdateWorker.perform_async(instagram_channel.account_id, status.to_s, params.as_json)
      end

      def lock_key(entry, parsed_message)
        format(
          ::RedisUtilities::Keys::INSTAGRAM_MESSAGE_CREATION_LOCK,
          instagram_id: entry[:id],
          sender_id: parsed_message.sender_id
        )
      end
    end
  end
end
