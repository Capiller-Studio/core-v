# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Webhooks
  class WhatsappEventListenWorker < BaseMutexWorker
    def perform(webhook_id)
      webhook = Webhook::Incoming.find_by(id: webhook_id)
      return unless webhook

      begin
        params = webhook.payload.with_indifferent_access

        processed = false
        if params["object"] == "whatsapp_business_account"
          processed = process_via_global_routing(params)
        end

        process_via_channel_id(webhook) unless processed

        webhook.processed!
      rescue => e
        webhook.update!(status: :failed, error_message: "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        raise(e)
      end
    end

    private

    # Preferred path: resolve channel via phone_number_id from webhook payload using GlobalRouting
    def process_via_global_routing(params)
      phone_number_id = params.dig("entry", 0, "changes", 0, "value", "metadata", "phone_number_id")&.to_s
      return false if phone_number_id.blank?

      routing = GlobalRouting.find_account_for("whatsapp", phone_number_id)
      return false unless routing

      account = routing.account
      return false unless account

      Current.set(account: account) do
        account.with_shard do
          channel = Channel::Whatsapp.find_by(phone_number_id: phone_number_id, account_id: account.id)
          return false unless channel_active?(channel)
          return false unless channel.cloud_api?

          Channels::Whatsapp::CloudApi::EventListener.call(
            whatsapp_channel: channel,
            params: params
          )
        end
      end
      true
    rescue StandardError => e
      Rails.logger.error("WhatsappEventListenWorker routing error: #{e.message}")
      false
    end

    # Fallback: channel_id passed directly in URL (for manual webhook setup)
    def process_via_channel_id(webhook)
      params = webhook.payload.with_indifferent_access

      route_params = webhook.route_params
      query_params = webhook.query_params

      channel_id = query_params["channel_id"] || route_params[:channel_id]
      account_id = query_params["account_id"] || route_params[:account_id]

      return unless channel_id && account_id

      account = Account.find_by(id: account_id)
      return unless account

      account.with_shard do
        channel = Channel::Whatsapp.find_by(id: channel_id)
        return unless channel_active?(channel)
        return unless channel.cloud_api?

        Current.set(account: channel.account) do
          Channels::Whatsapp::CloudApi::EventListener.call(
            whatsapp_channel: channel,
            params: params
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error("WhatsappEventListenWorker channel lookup error: #{e.message}")
    end

    def channel_active?(channel)
      return false if channel.blank? || channel.reauthorization_required? || !channel.active? || !channel.account.active?

      true
    end
  end
end
