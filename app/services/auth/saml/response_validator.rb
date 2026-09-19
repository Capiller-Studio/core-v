# frozen_string_literal: true

require "onelogin/ruby-saml"

module Auth
  module Saml
    class ResponseValidator < ApplicationService
      ValidationResult = Struct.new(
        :success,
        :name_id,
        :email,
        :first_name,
        :last_name,
        :groups,
        :attributes,
        :error_code,
        :error_message,
        keyword_init: true
      ) do
        def success?
          success == true
        end

        def failure?
          !success?
        end
      end

      attr_reader :raw_response, :config, :host

      def initialize(raw_response, sso_configuration, host = nil)
        @raw_response = raw_response
        @config = sso_configuration
        @host = host
      end

      def call
        return failure_result("blank_response", "SAMLResponse parameter is missing") if raw_response.blank?

        settings = SettingsBuilder.call(config, host)
        saml_response = OneLogin::RubySaml::Response.new(
          raw_response,
          settings: settings,
          allowed_clock_drift: 60
        )

        # 1. Validate cryptographic signatures, timestamps, and conditions
        unless saml_response.is_valid?
          error_msgs = saml_response.errors.join("; ")
          return failure_result("invalid_saml_response", error_msgs)
        end

        # 2. Prevent SAML replay attacks via Redis
        response_id = saml_response.response_id
        if response_id.present?
          replay_key = RedisUtilities::Keys::AUTH_SAML_REPLAY % { response_id: response_id }
          if RedisUtilities::Helpers.exists?(replay_key)
            Auth::AuditLog.log(
              event_type:    :replay_attack_blocked,
              auth_method:   :saml,
              status:        :failure,
              account:       config.account,
              email:         saml_response.name_id,
              error_code:    "replay_detected",
              error_message: "Replay attack detected for SAML Response ID: #{response_id}",
              metadata:      { response_id: response_id, idp_entity_id: config.idp_entity_id }
            )
            return failure_result("replay_detected", "A SAML response with this ID was already processed")
          end

          # Store ResponseID with expiry matching NotOnOrAfter (min 300s, max 3600s)
          ttl = 300
          if saml_response.not_on_or_after.present?
            ttl = [(saml_response.not_on_or_after - Time.current).to_i, 60].max
            ttl = [ttl, 3600].min
          end
          RedisUtilities::Helpers.set(replay_key, "1", expiry: ttl)
        end

        # 3. Extract and normalize attributes
        extracted_attributes = extract_attributes(saml_response)

        ValidationResult.new(
          success:       true,
          name_id:       saml_response.name_id,
          email:         extracted_attributes[:email],
          first_name:    extracted_attributes[:first_name],
          last_name:     extracted_attributes[:last_name],
          groups:        extracted_attributes[:groups],
          attributes:    saml_response.attributes.to_h,
          error_code:    nil,
          error_message: nil
        )
      rescue StandardError => e
        Rails.logger.error("Auth::Saml::ResponseValidator exception: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
        failure_result("validation_exception", e.message)
      end

      private

      def failure_result(code, message)
        ValidationResult.new(
          success:       false,
          name_id:       nil,
          email:         nil,
          first_name:    nil,
          last_name:     nil,
          groups:        [],
          attributes:    {},
          error_code:    code,
          error_message: message
        )
      end

      def extract_attributes(saml_response)
        attrs = saml_response.attributes
        mapping = config.attribute_mapping || {}

        email = fetch_mapped(attrs, mapping["email"]) ||
                first_present_attr(attrs, [
                  "email", "mail", "emailAddress", "User.Email",
                  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
                ]) ||
                (saml_response.name_id.to_s.match?(URI::MailTo::EMAIL_REGEXP) ? saml_response.name_id : nil)

        first_name = fetch_mapped(attrs, mapping["first_name"]) ||
                     first_present_attr(attrs, [
                       "firstName", "first_name", "givenName", "User.FirstName",
                       "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
                     ])

        last_name = fetch_mapped(attrs, mapping["last_name"]) ||
                    first_present_attr(attrs, [
                      "lastName", "last_name", "surname", "User.LastName",
                      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
                    ])

        groups = fetch_multi_attr(attrs, mapping["groups"])
        if groups.empty?
          ["groups", "memberOf", "http://schemas.xmlsoap.org/claims/Group"].each do |candidate|
            found = fetch_multi_attr(attrs, candidate)
            if found.present?
              groups = found
              break
            end
          end
        end

        parsed_groups = Array(groups).flatten
        parsed_groups.compact!

        {
          email:      email&.to_s&.strip&.downcase,
          first_name: first_name&.to_s&.strip,
          last_name:  last_name&.to_s&.strip,
          groups:     parsed_groups
        }
      end

      def fetch_multi_attr(attrs, key)
        return [] if key.blank?

        if attrs.respond_to?(:multi)
          vals = attrs.multi(key)
          return Array(vals) if vals.present?
        end

        if attrs.respond_to?(:all) && attrs.all[key].present?
          return Array(attrs.all[key])
        end

        Array(attrs[key])
      end

      def fetch_mapped(attrs, key)
        return nil if key.blank?

        val = attrs[key]
        val.is_a?(Array) ? val.first : val
      end

      def first_present_attr(attrs, candidates)
        candidates.each do |candidate|
          val = attrs[candidate]
          if val.present?
            return val.is_a?(Array) ? val.first : val
          end
        end
        nil
      end
    end
  end
end
