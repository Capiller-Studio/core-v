# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 1.0.0
# Website: https://techbolic.com/

module Channels
  module FacebookPages
    class TokenExchangeService < ApplicationService
      attr_reader :short_lived_token, :account

      def initialize(short_lived_token:, account:)
        @short_lived_token = short_lived_token
        @account = account
      end

      # Exchanges a short-lived user access token (from FB JS SDK login) for:
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
        long_lived_token = exchange_for_long_lived_token
        pages = fetch_pages(long_lived_token)

        {
          user_access_token: long_lived_token,
          pages: pages.map { |p| normalize_page(p) }
        }
      end

      private

      def exchange_for_long_lived_token
        oauth = Koala::Facebook::OAuth.new(
          Rails.application.credentials.dig(:channels, :facebook, :app_id),
          Rails.application.credentials.dig(:channels, :facebook, :app_secret)
        )
        result = oauth.exchange_access_token_info(short_lived_token)
        result["access_token"]
      end

      def fetch_pages(token)
        client = Koala::Facebook::API.new(token)
        client.get_connections(
          "me", "accounts",
          fields: "id,name,access_token,category,picture{url},instagram_business_account{id,username,profile_picture_url}"
        )
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
