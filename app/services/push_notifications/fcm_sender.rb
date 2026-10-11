# frozen_string_literal: true

require "openssl"
require "jwt"
require "net/http"
require "uri"
require "json"

module PushNotifications
  class FcmSender < ApplicationService
    attr_reader :channel, :device, :payload

    GOOGLE_TOKEN_URI = "https://oauth2.googleapis.com/token"
    FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

    def initialize(channel:, device:, payload:)
      @channel = channel
      @device  = device
      @payload = payload
    end

    def call
      return false unless channel.fcm_configured? && device.push_token.present?

      access_token = fetch_access_token
      return false if access_token.blank?

      send_fcm_v1(access_token)
    rescue StandardError => e
      Rails.logger.error("[PushNotifications::FcmSender] Error sending FCM push to device #{device.id}: #{e.message}")
      false
    end

    private

    def service_account
      @service_account ||= begin
        JSON.parse(channel.fcm_service_account)
      rescue StandardError => e
        Rails.logger.error("[PushNotifications::FcmSender] Invalid service account JSON: #{e.message}")
        nil
      end
    end

    def project_id
      channel.fcm_project_id.presence || service_account&.dig("project_id")
    end

    def fetch_access_token
      return nil unless service_account

      cache_key = "fcm_oauth_token:#{channel.id}:#{project_id}"
      cached = RedisUtilities::Helpers.get(cache_key)
      return cached if cached.present?

      now = Time.current.to_i
      jwt_claim = {
        iss: service_account["client_email"],
        scope: FCM_SCOPE,
        aud: GOOGLE_TOKEN_URI,
        exp: now + 3600,
        iat: now
      }

      private_key = OpenSSL::PKey::RSA.new(service_account["private_key"])
      assertion = JWT.encode(jwt_claim, private_key, "RS256")

      uri = URI(GOOGLE_TOKEN_URI)
      res = Net::HTTP.post_form(uri, {
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion" => assertion
      })

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        token = data["access_token"]
        expires_in = (data["expires_in"] || 3600).to_i
        RedisUtilities::Helpers.set(cache_key, token, expiry: [expires_in - 300, 60].max)
        token
      else
        Rails.logger.error("[PushNotifications::FcmSender] OAuth2 token exchange failed: #{res.code} - #{res.body}")
        nil
      end
    end

    def send_fcm_v1(access_token)
      endpoint = "https://fcm.googleapis.com/v1/projects/#{project_id}/messages:send"
      uri = URI(endpoint)

      fcm_body = {
        message: {
          token: device.push_token,
          notification: {
            title: payload[:title],
            body: payload[:body]
          },
          data: (payload[:data] || {}).transform_values(&:to_s),
          android: {
            priority: "high",
            notification: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
              sound: "default",
              channel_id: "deskbolic_support"
            }
          }
        }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Bearer #{access_token}"
      request["Content-Type"] = "application/json; UTF-8"
      request.body = fcm_body.to_json

      response = http.request(request)

      case response.code.to_i
      when 200..299
        device.update_columns(last_push_at: Time.current)
        true
      when 404, 400, 410
        # Invalidate dead/unregistered device token
        device.invalidate!("FCM response: #{response.code} - #{response.body}")
        false
      else
        Rails.logger.warn("[PushNotifications::FcmSender] FCM send returned #{response.code}: #{response.body}")
        false
      end
    end
  end
end
