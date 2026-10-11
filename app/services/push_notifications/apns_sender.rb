# frozen_string_literal: true

require "openssl"
require "jwt"
require "typhoeus"
require "json"

module PushNotifications
  class ApnsSender < ApplicationService
    attr_reader :channel, :device, :payload

    APNS_HOST_PROD    = "api.push.apple.com"
    APNS_HOST_SANDBOX = "api.sandbox.push.apple.com"

    def initialize(channel:, device:, payload:)
      @channel = channel
      @device  = device
      @payload = payload
    end

    def call
      return false unless channel.apns_configured? && device.push_token.present?

      bearer_token = generate_apns_jwt
      return false if bearer_token.blank?

      send_apns_http2(bearer_token)
    rescue StandardError => e
      Rails.logger.error("[PushNotifications::ApnsSender] Error sending APNs push to device #{device.id}: #{e.message}")
      false
    end

    private

    def host
      channel.apns_production? ? APNS_HOST_PROD : APNS_HOST_SANDBOX
    end

    def generate_apns_jwt
      cache_key = "apns_jwt_token:#{channel.id}:#{channel.apns_key_id}"
      cached = RedisUtilities::Helpers.get(cache_key)
      return cached if cached.present?

      ec_key = OpenSSL::PKey::EC.new(channel.apns_key)
      header = {
        alg: "ES256",
        kid: channel.apns_key_id
      }
      claims = {
        iss: channel.apns_team_id,
        iat: Time.current.to_i
      }

      token = JWT.encode(claims, ec_key, "ES256", header)
      RedisUtilities::Helpers.set(cache_key, token, expiry: 50.minutes.to_i)
      token
    rescue StandardError => e
      Rails.logger.error("[PushNotifications::ApnsSender] Failed to generate APNs JWT: #{e.message}")
      nil
    end

    def send_apns_http2(bearer_token)
      url = "https://#{host}/3/device/#{device.push_token}"

      apns_payload = {
        aps: {
          alert: {
            title: payload[:title],
            body: payload[:body]
          },
          badge: payload[:badge] || 1,
          sound: "default"
        }
      }.merge(payload[:data] || {})

      request = Typhoeus::Request.new(
        url,
        method: :post,
        body: apns_payload.to_json,
        headers: {
          "authorization" => "bearer #{bearer_token}",
          "apns-topic"     => channel.apns_bundle_id,
          "apns-push-type" => "alert",
          "apns-priority"  => "10",
          "content-type"   => "application/json"
        },
        timeout: 5,
        connecttimeout: 5,
        http_version: :httpv2_0
      )

      response = request.run

      case response.code
      when 200..299
        device.update_columns(last_push_at: Time.current)
        true
      when 410, 400
        # 410 = Unregistered (app uninstalled), 400 = BadDeviceToken
        device.invalidate!("APNs response: #{response.code} - #{response.body}")
        false
      else
        Rails.logger.warn("[PushNotifications::ApnsSender] APNs request failed: #{response.code} - #{response.body}")
        false
      end
    end
  end
end
