# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    class SignupService < ApplicationService
      attr_reader :code, :account

      def initialize(code:, account:)
        @code = code
        @account = account
      end

      def call
        token = exchange_code_for_token
        
        # Meta returns all WABAs shared with this app for this user
        client = Koala::Facebook::API.new(token)
        # Note: 'me/client_whatsapp_business_accounts' is the standard endpoint but some apps use 'me/whatsapp_business_accounts'
        # We try the standard ones.
        wabas = fetch_wabas(client)
        raise("No WhatsApp Business Accounts found for this user.") if wabas.blank?

        # For simplicity, we grab the first WABA and its first phone number.
        # In a more complex integration, you'd present a selector UI like Facebook Pages.
        waba = wabas.first
        phone_numbers = fetch_phone_numbers(client, waba["id"])
        
        raise("No Phone Numbers found in the WhatsApp Business Account.") if phone_numbers.blank?
        phone = phone_numbers.first

        {
          access_token: token,
          waba_id: waba["id"],
          phone_number_id: phone["id"],
          display_phone_number: phone["display_phone_number"]
        }
      end

      private

      def exchange_code_for_token
        app_id = Rails.application.credentials.dig(:channels, :whatsapp, :app_id)
        app_secret = Rails.application.credentials.dig(:channels, :whatsapp, :app_secret)
        
        # Exchange JS SDK code for long lived token
        oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
        
        # Note: JS SDK 'code' exchange doesn't strictly need a redirect_uri but Koala might require one
        # Koala's exchange_access_token_info handles short-lived tokens, but for 'code' we might need get_access_token
        # However, FB.login with response_type: 'code' actually requires using a specific endpoint.
        # But wait! If we just change JS to use response_type="token" (short-lived), we can just exchange it for long-lived.
        # Since we used "code" in JS, we use oauth.get_access_token(code)
        
        # We need to manually build the URL for 'code' exchange because Koala expects a redirect_uri for get_access_token
        # Actually, for Embedded Signup, the Facebook docs state:
        response = HTTParty.get("https://graph.facebook.com/v25.0/oauth/access_token", query: {
          client_id: app_id,
          client_secret: app_secret,
          code: code
        })

        if response.success? && response["access_token"]
          response["access_token"]
        else
          raise("Failed to exchange code for token: #{response.body}")
        end
      end

      def fetch_wabas(client)
        # For a tech provider, the user grants 'whatsapp_business_management'
        # So we can list the accounts they shared with us:
        response = client.get_connections("me", "accounts") # fallback maybe?
        
        # The correct endpoint for WABAs:
        begin
          client.get_object("me/client_whatsapp_business_accounts")
        rescue StandardError
          # Fallback to standard graph api if client API fails
          HTTParty.get("https://graph.facebook.com/v25.0/me/client_whatsapp_business_accounts", headers: { "Authorization" => "Bearer #{client.access_token}" }).parsed_response["data"] || []
        end
      end

      def fetch_phone_numbers(client, waba_id)
        begin
          client.get_connections(waba_id, "phone_numbers")
        rescue StandardError
          HTTParty.get("https://graph.facebook.com/v25.0/#{waba_id}/phone_numbers", headers: { "Authorization" => "Bearer #{client.access_token}" }).parsed_response["data"] || []
        end
      end
    end
  end
end
