# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Webhooks
  class WhatsappEventListenWorker < BaseMutexWorker
    def perform(params = {})
      params = params.with_indifferent_access

      if params["object"] == "whatsapp_business_account"
        process_via_global_routing(params)
      else
        process_via_channel_id(params)
      end
    end

    private

    # Preferred path: resolve channel via phone number from webhook payload using GlobalRouting
    def process_via_global_routing(params)
      phone_number = "+#{params['entry'].first['changes'].first.dig('value', 'metadata', 'display_phone_number')}"
      phone_number_id = params["entry"].first["changes"].first.dig("value", "metadata", "phone_number_id")

      routing = GlobalRouting.find_account_for("whatsapp", phone_number)
      return unless routing

      Current.set(account: routing.account) do
        routing.account.with_shard do
          channel = Channel::Whatsapp.find_by(full_phone_number: phone_number, account_id: routing.account_id)
          return unless channel_active?(channel)
          return unless channel.phone_number_id == phone_number_id
          return unless channel.cloud_api?

          Channels::Whatsapp::CloudApi::EventListener.call(
            whatsapp_channel: channel,
            params: params
          )
        end
      end
    rescue StandardError => e
      Rails.logger.error("WhatsappEventListenWorker routing error: #{e.message}")
    end

    # Fallback: channel_id passed directly (for manual webhook setup)
    def process_via_channel_id(params)
      channel_id = params["channel_id"]
      account_id = params["account_id"]
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
