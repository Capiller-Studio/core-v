# frozen_string_literal: true

module Webhooks
  module Sms
    class AwsSnsController < Webhooks::BaseController
      before_action :find_channel
      before_action :verify_signature

      def create
        raw_body = request.raw_post
        aws_json = JSON.parse(raw_body) rescue {}

        webhook = store_incoming_webhook(source: "aws_sns", payload: aws_json)
        Webhooks::AwsSnsEventListenWorker.perform_async(webhook.id)

        head(:ok)
      rescue StandardError => e
        Rails.logger.error("AWS SNS Webhook failed: #{e.message}")
        head(:internal_server_error)
      end

      private

      def find_channel
        @channel = Channel::ShortMessage.aws_sns.find_by(account_id: params[:account_id], id: params[:channel_id])
        head(:not_found) unless @channel
      end

      def verify_signature
        # AWS explicitly signs requests verifying them using public keys natively
        verifier = Aws::SNS::MessageVerifier.new

        unless verifier.authentic?(request.raw_post)
          head(:unauthorized)
        end
      rescue Aws::SNS::MessageVerifier::VerificationError
        head(:unauthorized)
      end
    end
  end
end
