# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module Instagram
    class OauthService < ApplicationService
      include HTTParty

      REQUIRED_SCOPES = %w[
        instagram_business_basic
        instagram_business_manage_messages
      ].freeze

      SUBSCRIBED_FIELDS = %w[
        messages
        message_reactions
        message_edit
        messaging_postbacks
        messaging_seen
        standby
      ].freeze

      API_VERSION = "v26.0"

      attr_reader :account

      def initialize(account:)
        @account = account
      end

      # Generate the Instagram OAuth authorization URL.
      # The user will be redirected to Instagram to grant permissions.
      def authorization_url(redirect_uri:, state:)
        params = {
          client_id: instagram_app_id,
          redirect_uri: redirect_uri,
          scope: REQUIRED_SCOPES.join(","),
          response_type: "code",
          enable_fb_login: "0",
          force_authentication: "1",
          state: state
        }

        "https://www.instagram.com/oauth/authorize?#{params.to_query}"
      end

      # Exchange the authorization code for a short-lived access token,
      # then exchange it for a long-lived token (60 days, refreshable).
      # Also fetches user profile details.
      #
      # Returns a Hash:
      #   {
      #     access_token: "...",
      #     expires_at: <Time>,
      #     user: { id: "...", username: "...", name: "...", avatar_url: "..." }
      #   }
      def exchange_code(code:, redirect_uri:)
        short_lived = exchange_code_for_token(code, redirect_uri)
        long_lived = exchange_for_long_lived_token(short_lived["access_token"])
        user_details = fetch_user_details(long_lived["access_token"])
        instagram_id = (user_details["user_id"].presence || user_details["id"]).to_s

        subscribe_to_webhooks(instagram_id, long_lived["access_token"])

        {
          access_token: long_lived["access_token"],
          expires_at: Time.current + long_lived["expires_in"].to_i.seconds,
          user: {
            id: instagram_id,
            username: user_details["username"],
            name: user_details["name"],
            avatar_url: user_details["profile_picture_url"]
          }
        }
      end

      private

      def instagram_app_id
        Rails.application.credentials.dig(:channels, :instagram, :app_id)
      end

      def instagram_app_secret
        Rails.application.credentials.dig(:channels, :instagram, :app_secret)
      end

      # Step 1: Exchange authorization code for short-lived token
      def exchange_code_for_token(code, redirect_uri)
        response = self.class.post(
          "https://api.instagram.com/oauth/access_token",
          body: {
            client_id: instagram_app_id,
            client_secret: instagram_app_secret,
            grant_type: "authorization_code",
            redirect_uri: redirect_uri,
            code: code
          },
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        )

        handle_response(response, "Failed to exchange authorization code")
      end

      # Step 2: Exchange short-lived token for long-lived token (60 days)
      def exchange_for_long_lived_token(short_lived_token)
        response = self.class.get(
          "https://graph.instagram.com/access_token",
          query: {
            grant_type: "ig_exchange_token",
            client_secret: instagram_app_secret,
            access_token: short_lived_token
          }
        )

        handle_response(response, "Failed to exchange for long-lived token")
      end

      # Step 3: Fetch user profile details
      def fetch_user_details(access_token)
        response = self.class.get(
          "https://graph.instagram.com/#{API_VERSION}/me",
          query: {
            fields: "id,username,user_id,name,profile_picture_url,account_type",
            access_token: access_token
          }
        )

        handle_response(response, "Failed to fetch Instagram user details")
      end

      def subscribe_to_webhooks(instagram_id, access_token)
        response = self.class.post(
          "https://graph.instagram.com/#{API_VERSION}/#{instagram_id}/subscribed_apps",
          query: {
            subscribed_fields: SUBSCRIBED_FIELDS.join(","),
            access_token: access_token
          }
        )

        handle_response(response, "Failed to subscribe Instagram webhooks")
      end

      def handle_response(response, error_prefix)
        unless response.success?
          Rails.logger.error("#{error_prefix}. Status: #{response.code}, Body: #{response.body}")
          raise("#{error_prefix}: #{response.body}")
        end

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error("Invalid JSON response from Instagram: #{response.body}")
        raise(e)
      end
    end
  end
end
