# frozen_string_literal: true

module Webhooks
  module Sms
    class SignalwireController < Webhooks::BaseController
      before_action :find_channel
      before_action :verify_signature

      def create
        webhook = store_incoming_webhook(source: "signalwire", payload: request.POST.to_h)
        Webhooks::SignalwireEventListenWorker.perform_async(webhook.id)

        head(:ok)
      rescue StandardError => e
        Rails.logger.error("Signalwire Webhook failed: #{e.message}")
        head(:internal_server_error)
      end

      private

      def find_channel
        @channel = Channel::ShortMessage.signalwire.find_by(account_id: params[:account_id], id: params[:channel_id])
        head(:not_found) unless @channel
      end

      def verify_signature
        # Signalwire uses the exact identical security signature validation logic natively
        # using the Twilio-compatible Security validator mapped with Signalwires Token.
        validator = Twilio::Security::RequestValidator.new(auth_token)
        signature = request.headers["X-Twilio-Signature"] || request.headers["X-SignalWire-Signature"]

        url = request.original_url

        unless validator.validate(url, request.POST, signature)
          head(:unauthorized)
        end
      end

      def auth_token
        @channel.configurations["token"] || @channel.configurations[:token]
      end
    end
  end
end
