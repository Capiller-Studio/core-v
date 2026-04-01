# frozen_string_literal: true

module Webhooks
  class FacebookEventListenWorker < BaseMutexWorker
    def perform(event_name, payload)
      parsed_message = Parser::FacebookMessageParser.new(response: payload)

      case event_name.to_sym
      when :message, :message_echo
        process_message(parsed_message, event_name.to_sym)
      when :delivery, :read
        process_status(parsed_message, event_name.to_sym)
      end
    end

    private

    def process_message(parsed_message, event_name)
      search_id = event_name == :message_echo ? parsed_message.sender_id : parsed_message.recipient_id

      lock_key = format(
        RedisUtilities::Keys::FACEBOOK_MESSAGE_CREATION_LOCK,
        receiver_id: search_id,
        sender_id: event_name == :message_echo ? parsed_message.recipient_id : parsed_message.sender_id
      )

      RedisUtilities::MutexHelpers.with_lock(lock_key) do
        Channel::FacebookPage.where(page_identifier: search_id).find_each do |channel|
          Channels::FacebookPages::ConversationCreator.call(
            facebook_page_channel: channel,
            parsed_message: parsed_message
          )
        end
      end
    end

    def process_status(parsed_message, event_name)
      watermark = event_name == :read ? parsed_message.read_watermark : parsed_message.delivery_watermark
      return unless watermark

      status = event_name == :read ? :read : :delivered

      # For read/delivery receipts, the recipient is our page
      Channel::FacebookPage.where(page_identifier: parsed_message.recipient_id).find_each do |channel|
        params = {
          watermark: watermark,
          customer_external_id: parsed_message.sender_id,
          channel_class: channel.class.name,
          channel_id: channel.id
        }
        Messages::StatusUpdateWorker.perform_async(channel.account_id, status, params)
      end
    end
  end
end
