# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class TokenExchangeService < ApplicationService
      attr_reader :code, :redirect_uri, :short_lived_token, :account

      def initialize(account:, code: nil, redirect_uri: nil, short_lived_token: nil)
        @account = account
        @code = code
        @redirect_uri = redirect_uri
        @short_lived_token = short_lived_token
      end

      # Exchanges an OAuth authorization code or short-lived token for:
      # 1. A long-lived user access token (valid 60 days)
      # 2. A list of pages the user manages (each with a permanent page access token)
      #
      # Returns a Hash:
      #   {
      #     user_access_token: "...",
      #     pages: [
      #       { id: "123", name: "My Page", access_token: "...", category: "...", avatar_url: "...", instagram_business_account: { ... } },
      #       ...
      #     ]
      #   }
      def call
        user_token = if code.present?
          initial_token = exchange_code_for_user_token
          exchange_for_long_lived_token(initial_token)
        else
          exchange_for_long_lived_token(short_lived_token)
        end

        pages = fetch_pages(user_token)

        {
          user_access_token: user_token,
          pages: pages.map { |p| normalize_page(p) }
        }
      end

      private

      def exchange_code_for_user_token
        app_id = Rails.application.credentials.dig(:channels, :facebook, :app_id)&.to_s&.strip
        app_secret = Rails.application.credentials.dig(:channels, :facebook, :app_secret)&.to_s&.strip

        response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/oauth/access_token",
          query: {
            client_id: app_id,
            client_secret: app_secret,
            redirect_uri: redirect_uri,
            code: code.to_s.strip
          }
        )

        if response.success? && response["access_token"].present?
          response["access_token"]
        else
          raise("Failed to exchange code for Facebook access token: #{response.body}")
        end
      end

      def exchange_for_long_lived_token(token)
        oauth = Koala::Facebook::OAuth.new(
          Rails.application.credentials.dig(:channels, :facebook, :app_id)&.to_s&.strip,
          Rails.application.credentials.dig(:channels, :facebook, :app_secret)&.to_s&.strip
        )
        result = oauth.exchange_access_token_info(token)
        result["access_token"].presence || token
      rescue StandardError => e
        Rails.logger.warn("Facebook long-lived token exchange notice: #{e.message}")
        token
      end

      def fetch_pages(token)
        client = Koala::Facebook::API.new(token)
        client.get_connections(
          "me", "accounts",
          fields: "id,name,access_token,category,picture{url},instagram_business_account{id,username,profile_picture_url}"
        )
      rescue StandardError
        # Fallback to direct HTTParty call if Koala encounters issues
        response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/me/accounts",
          headers: { "Authorization" => "Bearer #{token}" },
          query: { fields: "id,name,access_token,category,picture{url},instagram_business_account{id,username,profile_picture_url}" }
        )
        response.parsed_response["data"] || []
      end

      def normalize_page(page)
        {
          id: page["id"],
          name: page["name"],
          access_token: page["access_token"],
          category: page["category"],
          avatar_url: page.dig("picture", "data", "url"),
          instagram_business_account: page["instagram_business_account"]
        }
      end
    end
  end
end
