# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    class SignupService < ApplicationService
      attr_reader :code, :account, :redirect_uri, :provided_waba_id, :provided_phone_number_id

      def initialize(code:, account:, redirect_uri: nil, waba_id: nil, phone_number_id: nil)
        @code = code
        @account = account
        @redirect_uri = redirect_uri.presence
        @provided_waba_id = waba_id.presence
        @provided_phone_number_id = phone_number_id.presence
      end

      def call
        token = exchange_code_for_token
        client = Koala::Facebook::API.new(token)

        # Inspect token to extract granular scopes (WABA ID and Phone Number ID from Embedded Signup)
        inspected_info = inspect_token_scopes(token)

        # 1. Resolve WABA ID (from session_info, token inspection, or Graph API discovery)
        waba_id = provided_waba_id.presence || inspected_info[:waba_id].presence || discover_waba_id(client)
        raise("No WhatsApp Business Accounts found for this user.") if waba_id.blank?

        # 2. Subscribe our Tech Provider App to the client's WABA webhooks
        subscribe_waba_webhooks(waba_id, token)

        # 3. Resolve Phone Number ID (from session_info, token inspection, or Graph API discovery)
        phone_number_id = provided_phone_number_id.presence || inspected_info[:phone_number_id].presence || discover_phone_number_id(client, waba_id)
        raise("No Phone Numbers found in the WhatsApp Business Account.") if phone_number_id.blank?

        # 4. Fetch phone number details (display number, verified name)
        phone_details = fetch_phone_details(client, phone_number_id, waba_id)

        # 5. Ensure phone number is registered for Cloud API messaging
        register_phone_number_if_needed(phone_number_id, token)

        {
          access_token: token,
          waba_id: waba_id,
          phone_number_id: phone_number_id,
          display_phone_number: phone_details[:display_phone_number],
          name: phone_details[:verified_name].presence || phone_details[:display_phone_number]
        }
      end

      private

      def whatsapp_app_id
        (Rails.application.credentials.dig(:channels, :whatsapp, :app_id).presence ||
         Rails.application.credentials.dig(:channels, :facebook, :app_id))&.to_s&.strip
      end

      def whatsapp_app_secret
        (Rails.application.credentials.dig(:channels, :whatsapp, :app_secret).presence ||
         Rails.application.credentials.dig(:channels, :facebook, :app_secret))&.to_s&.strip
      end

      def exchange_code_for_token
        query_params = {
          client_id: whatsapp_app_id,
          client_secret: whatsapp_app_secret,
          code: code.to_s.strip
        }
        query_params[:redirect_uri] = redirect_uri if redirect_uri.present?

        response = HTTParty.get("https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/oauth/access_token", query: query_params)

        if response.success? && response["access_token"].present?
          response["access_token"]
        else
          raise("Failed to exchange code for token: #{response.body}")
        end
      end

      # Inspects the OAuth access token to extract WABA ID and Phone Number ID from granular_scopes
      def inspect_token_scopes(token)
        app_id = whatsapp_app_id
        app_secret = whatsapp_app_secret
        return {} if app_id.blank? || app_secret.blank?

        app_access_token = "#{app_id}|#{app_secret}"
        response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/debug_token",
          query: { input_token: token, access_token: app_access_token }
        )

        return {} unless response.success?

        data = response.parsed_response["data"] || {}
        granular_scopes = data["granular_scopes"] || []

        discovered_waba_id = nil
        discovered_phone_id = nil

        granular_scopes.each do |scope_info|
          scope = scope_info["scope"]
          target_ids = scope_info["target_ids"] || []

          if scope == "whatsapp_business_management"
            discovered_waba_id ||= target_ids.first
          elsif scope == "whatsapp_business_messaging"
            discovered_phone_id ||= target_ids.first
          end
        end

        { waba_id: discovered_waba_id, phone_number_id: discovered_phone_id }
      rescue StandardError => e
        Rails.logger.warn("WhatsApp debug_token inspection error: #{e.message}")
        {}
      end

      def discover_waba_id(client)
        # 1. Try me/client_whatsapp_business_accounts (Tech Provider standard)
        wabas = fetch_client_wabas(client)
        return wabas.first["id"] if wabas.present? && wabas.first&.[]("id").present?

        # 2. Try me/whatsapp_business_accounts (Direct user WABAs)
        direct_wabas = fetch_direct_wabas(client)
        return direct_wabas.first["id"] if direct_wabas.present? && direct_wabas.first&.[]("id").present?

        # 3. Try me/businesses -> owned_whatsapp_business_accounts / client_whatsapp_business_accounts
        business_wabas = fetch_business_wabas(client)
        return business_wabas.first["id"] if business_wabas.present? && business_wabas.first&.[]("id").present?

        nil
      end

      def fetch_client_wabas(client)
        begin
          client.get_object("me/client_whatsapp_business_accounts")
        rescue StandardError
          HTTParty.get(
            "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/me/client_whatsapp_business_accounts",
            headers: { "Authorization" => "Bearer #{client.access_token}" }
          ).parsed_response["data"] || []
        end
      end

      def fetch_direct_wabas(client)
        response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/me/whatsapp_business_accounts",
          headers: { "Authorization" => "Bearer #{client.access_token}" }
        )
        response.parsed_response["data"] || []
      rescue StandardError
        []
      end

      def fetch_business_wabas(client)
        businesses_resp = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/me/businesses",
          headers: { "Authorization" => "Bearer #{client.access_token}" }
        )
        businesses = businesses_resp.parsed_response["data"] || []

        businesses.each do |biz|
          biz_id = biz["id"]
          next if biz_id.blank?

          # Check owned WABAs under this business
          owned = HTTParty.get(
            "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{biz_id}/owned_whatsapp_business_accounts",
            headers: { "Authorization" => "Bearer #{client.access_token}" }
          ).parsed_response["data"] || []
          return owned if owned.present?

          # Check client WABAs under this business
          client_owned = HTTParty.get(
            "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{biz_id}/client_whatsapp_business_accounts",
            headers: { "Authorization" => "Bearer #{client.access_token}" }
          ).parsed_response["data"] || []
          return client_owned if client_owned.present?
        end

        []
      rescue StandardError
        []
      end

      def discover_phone_number_id(client, waba_id)
        phone_numbers = fetch_phone_numbers(client, waba_id)
        phone_numbers.first&.[]("id")
      end

      def fetch_phone_numbers(client, waba_id)
        begin
          client.get_connections(waba_id, "phone_numbers")
        rescue StandardError
          response = HTTParty.get(
            "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{waba_id}/phone_numbers",
            headers: { "Authorization" => "Bearer #{client.access_token}" }
          )
          response.parsed_response["data"] || []
        end
      end

      def fetch_phone_details(client, phone_number_id, waba_id)
        # Attempt direct fetch for the specific phone number
        response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{phone_number_id}",
          headers: { "Authorization" => "Bearer #{client.access_token}" }
        )

        if response.success? && response.parsed_response.present?
          parsed = response.parsed_response
          {
            display_phone_number: parsed["display_phone_number"],
            verified_name: parsed["verified_name"]
          }
        else
          # Fallback to searching the list of numbers in the WABA
          numbers = fetch_phone_numbers(client, waba_id)
          matched = numbers.find { |n| n["id"] == phone_number_id } || numbers.first
          {
            display_phone_number: matched&.[]("display_phone_number"),
            verified_name: matched&.[]("verified_name")
          }
        end
      end

      # Subscribes our app to receive incoming messages & status webhooks for this client WABA
      def subscribe_waba_webhooks(waba_id, token)
        response = HTTParty.post(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{waba_id}/subscribed_apps",
          headers: {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        )

        unless response.success?
          Rails.logger.warn("WhatsApp Tech Provider subscribed_apps warning for WABA #{waba_id}: #{response.body}")
        end
      rescue StandardError => e
        Rails.logger.error("Failed to subscribe WABA #{waba_id} webhooks: #{e.message}")
      end

      # Registers the phone number for Cloud API messaging if not already active
      def register_phone_number_if_needed(phone_number_id, token)
        # Check current registration status first
        status_response = HTTParty.get(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{phone_number_id}",
          headers: { "Authorization" => "Bearer #{token}" },
          query: { fields: "status,code_verification_status" }
        )

        if status_response.success? && status_response.parsed_response.is_a?(Hash)
          status = status_response.parsed_response["status"]
          verification = status_response.parsed_response["code_verification_status"]
          # If already verified/connected by Embedded Signup, skip /register call
          return if status == "CONNECTED" || verification == "VERIFIED"
        end

        # Only attempt registration if not yet connected/verified
        HTTParty.post(
          "https://graph.facebook.com/#{Channel::Whatsapp::GRAPH_API_VERSION}/#{phone_number_id}/register",
          headers: {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          },
          body: {
            messaging_product: "whatsapp",
            pin: "123456"
          }.to_json
        )
      rescue StandardError => e
        Rails.logger.warn("WhatsApp phone number registration notice: #{e.message}")
      end
    end
  end
end
