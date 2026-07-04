# frozen_string_literal: true

module Webhooks
  class CustomEventListenWorker
    include Sidekiq::Worker
    sidekiq_options queue: "default", retry: 3

    def perform(account_id, channel_id, payload)
      payload = payload.with_indifferent_access

      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        channel = Channel::Custom.find_by(id: channel_id)
        return unless channel_active?(channel)

        Current.set(account: account) do
          process_payload(channel, payload)
        end
      end
    rescue StandardError => e
      Rails.logger.error("CustomEventListenWorker error: #{e.message}")
      raise e # Re-raise for Sidekiq retry
    end

    private

    def process_payload(channel, payload)
      event = payload[:event]
      
      case event
      when "message.created"
        create_message(channel, payload)
      else
        Rails.logger.warn("CustomEventListenWorker: unsupported event type '#{event}'")
      end
    end

    def create_message(channel, payload)
      message_data = payload[:message]
      return if message_data.blank?

      # customer params to identify or create the customer
      customer_params = payload[:customer] || {}

      creator = Channels::Custom::ConversationCreator.new(
        custom_channel: channel,
        customer_params: customer_params,
        content: message_data[:content],
        attachments: [], # If attachments are URLs, they could be parsed here and attached
        conversation_data: payload[:conversation] || {},
        external_id: payload.dig(:conversation, :external_id)
      )

      creator.call
    end

    def channel_active?(channel)
      return false if channel.blank? || !channel.active? || !channel.account.active?

      true
    end
  end
end
