# frozen_string_literal: true

module Webhooks
  module Sms
    class AwsSnsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :find_channel
      before_action :verify_signature

      def create
        raw_body = request.raw_post
        aws_json = JSON.parse(raw_body) rescue {}

        # 1. AWS SNS Topic Registration Handshake
        if aws_json["Type"] == "SubscriptionConfirmation"
          # Confirm the subscription explicitly by fetching the dynamic URL
          HTTParty.get(aws_json["SubscribeURL"]) if aws_json["SubscribeURL"]
          return head(:ok)
        end

        # 2. Extract Notification organically
        if aws_json["Type"] == "Notification"
          Channels::ShortMessage::AwsSns::ConversationCreator.call(
            short_message_channel: @channel,
            parsed_params: aws_json
          )
        end

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
