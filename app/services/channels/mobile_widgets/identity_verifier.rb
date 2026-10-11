# frozen_string_literal: true

module Channels
  module MobileWidgets
    class IdentityVerifier < ApplicationService
      attr_reader :channel, :params

      def initialize(channel:, params:)
        @channel = channel
        @params  = (params || {}).with_indifferent_access
      end

      def call
        if params[:jwt].present?
          verify_jwt
        elsif params[:signature].present? && params[:identifier].present?
          verify_hmac
        elsif !channel.secure_identity_enforced?
          # Unverified / guest session allowed
          {
            external_id: params[:identifier],
            email: params[:email],
            name: params[:name],
            phone_number: params[:phone_number],
            avatar_url: params[:avatar_url],
            custom_attributes: params[:custom_attributes] || {}
          }
        else
          nil
        end
      end

      private

      # 1. Modern JWT (HS256) Verification (Zendesk & Intercom Standard)
      def verify_jwt
        decoded, _header = JWT.decode(
          params[:jwt],
          channel.secret,
          true,
          { algorithm: "HS256", verify_expiration: true }
        )
        payload = decoded.with_indifferent_access

        {
          external_id: payload[:sub] || payload[:user_id] || payload[:external_id],
          email: payload[:email],
          name: payload[:name],
          phone_number: payload[:phone_number],
          avatar_url: payload[:avatar_url],
          custom_attributes: payload[:custom_attributes] || {}
        }
      rescue JWT::ExpiredSignature => e
        Rails.logger.warn("[MobileWidget] Expired JWT signature: #{e.message}")
        nil
      rescue JWT::DecodeError => e
        Rails.logger.warn("[MobileWidget] Invalid JWT: #{e.message}")
        nil
      end

      # 2. Lightweight HMAC-SHA256 Verification (Crisp & WebWidget Standard)
      def verify_hmac
        expected = OpenSSL::HMAC.hexdigest("sha256", channel.secret, params[:identifier].to_s)
        return nil unless ActiveSupport::SecurityUtils.secure_compare(expected, params[:signature].to_s)

        {
          external_id: params[:identifier],
          email: params[:email],
          name: params[:name],
          phone_number: params[:phone_number],
          avatar_url: params[:avatar_url],
          custom_attributes: params[:custom_attributes] || {}
        }
      end
    end
  end
end
