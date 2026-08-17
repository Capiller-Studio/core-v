# frozen_string_literal: true

module Webhooks
  module Sms
    class TwilioController < Webhooks::BaseController
      before_action :find_channel
      before_action :verify_signature

      def create
        webhook = store_incoming_webhook(source: "twilio", payload: request.POST.to_h)
        Webhooks::TwilioEventListenWorker.perform_async(webhook.id)

        head(:ok)
      rescue StandardError => e
        Rails.logger.error("Twilio Webhook failed: #{e.message}")
        head(:internal_server_error)
      end

      private

      def find_channel
        account = Account.find_by(id: params[:account_id])
        return head(:not_found) unless account

        @channel = account.with_shard do
          Channel::ShortMessage.twilio.find_by(id: params[:channel_id])
        end
        head(:not_found) unless @channel
      end

      def verify_signature
        validator = Twilio::Security::RequestValidator.new(auth_token)
        signature = request.headers["X-Twilio-Signature"]

        # Determine the full requested URL organically
        url = request.original_url

        unless validator.validate(url, request.POST, signature)
          head(:unauthorized)
        end
      end

      def auth_token
        @channel.configurations["auth_token"] || @channel.configurations[:auth_token]
      end
    end
  end
end
