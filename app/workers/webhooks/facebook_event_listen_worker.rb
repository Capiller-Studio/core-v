# frozen_string_literal: true

module Webhooks
  class FacebookEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        event_name = webhook.event_type
        return if event_name.blank?

        # webhook.payload is already a Hash (JSONB). Re-serialize for the parser
        # which was built to accept a JSON string.
        payload = webhook.payload.to_json
        parsed_message = Parser::FacebookMessageParser.new(response: payload)

        case event_name.to_sym
        when :message, :message_echo
          process_message(parsed_message, event_name.to_sym)
        when :delivery, :read
          process_status(parsed_message, event_name.to_sym)
        when :reaction
          process_reaction(parsed_message)
        when :message_edit
          process_edit(parsed_message)
        when :message_unsend, :message_delete
          process_unsend(parsed_message)
        end

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise(e) # Let Sidekiq retry
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
        each_channel_for(search_id) do |channel|
          Channels::FacebookPages::ConversationCreator.call(
            facebook_page_channel: channel,
            parsed_message: parsed_message
          )
        end
      end
    end

    def process_reaction(parsed_message)
      each_channel_for(parsed_message.recipient_id) do |channel|
        Channels::FacebookPages::ReactionHandler.call(
          channel: channel,
          parsed_message: parsed_message
        )
      end
    end

    def process_edit(parsed_message)
      each_channel_for(parsed_message.recipient_id) do |channel|
        Channels::FacebookPages::EditHandler.call(
          channel: channel,
          parsed_message: parsed_message
        )
      end
    end

    def process_unsend(parsed_message)
      each_channel_for(parsed_message.recipient_id) do |channel|
        Channels::FacebookPages::UnsendHandler.call(
          channel: channel,
          parsed_message: parsed_message
        )
      end
    end

    def process_status(parsed_message, event_name)
      each_channel_for(parsed_message.recipient_id) do |channel|
        watermark = event_name == :read ? parsed_message.read_watermark : parsed_message.delivery_watermark
        message_external_ids = parsed_message.message&.dig(:mids) || []

        if event_name == :read && parsed_message.read&.dig("mid").present?
          message_external_ids << parsed_message.read["mid"]
        end

        next if watermark.blank? && message_external_ids.blank?

        status = event_name == :read ? :read : :delivered
        params = {
          external_ids: message_external_ids,
          watermark: watermark,
          customer_external_id: parsed_message.sender_id,
          channel_class: channel.class.name,
          channel_id: channel.id
        }

        Messages::StatusUpdateWorker.perform_async(channel.account_id, status, params.as_json)
      end
    end

    def each_channel_for(search_id, &block)
      return if search_id.blank?

      GlobalRouting.where(route_type: "facebook_page", route_value: search_id).find_each do |routing|
        Current.set(account: routing.account) do
          routing.account.with_shard do
            Channel::FacebookPage.where(page_identifier: search_id, account_id: routing.account_id).find_each do |channel|
              block.call(channel)
            end
          end
        end
      end
    end
  end
end
