# frozen_string_literal: true

module Identities
  class ApiFetcher < ApplicationService
    attr_reader :identity, :identity_source

    def initialize(identity:)
      @identity = identity
      @identity_source = identity.identity_source
    end

    def call
      raise "IdentitySource missing or not an API type" unless identity.custom_api? && identity_source.present?

      # 1. Prepare Liquid Context
      liquid_context = prepare_context

      # 2. Render URL, Headers, Params
      url = render_template(identity_source.source_url, liquid_context)
      headers = render_hash(identity_source.headers, liquid_context)
      params = render_hash(identity_source.params, liquid_context)

      # 3. Make HTTP Request
      response = execute_request(url, headers, params)

      # 4. Map the Raw Response
      parsed = parse_response(response)
      mapped_data = Identities::Mapper.call(
        identity_source: identity_source,
        raw_response: parsed
      )

      # 5. Update Identity Attributes
      update_identity!(parsed, mapped_data)
      
      identity
    rescue StandardError => e
      Rails.logger.error("Identities::ApiFetcher Error [Identity ID: #{identity.id}]: #{e.message}")
      
      # Still save raw response for debugging even on error
      identity.update!(
        raw_response: { error: e.message }
      )
      
      identity
    end

    private

    def prepare_context
      customer = identity.customer
      {
        "customer" => {
          "id" => customer.id,
          "email" => customer.email,
          "first_name" => customer.first_name,
          "last_name" => customer.last_name,
          "name" => customer.name,
          "identifier" => customer.identifier,
          "full_phone_number" => customer.full_phone_number,
          "external_id" => customer.external_id
        }.compact,
        "identity" => {
          "id" => identity.id,
          "identifier" => identity.identifier,
          "external_id" => identity.external_id
        }.compact
      }
    end

    def render_template(template, context)
      return template if template.blank?
      
      Liquid::Template.parse(template).render(context)
    end

    def render_hash(hash, context)
      return {} if hash.blank?
      
      result = {}
      hash.each do |k, v|
        result[k] = if v.is_a?(String)
                      render_template(v, context)
                    else
                      v
                    end
      end
      result
    end

    def execute_request(url, headers, params)
      # For now using GET request. HTTParty is generally available.
      HTTParty.get(
        url,
        headers: headers,
        query: params,
        timeout: 10
      )
    end

    def parse_response(response)
      response.parsed_response || JSON.parse(response.body)
    rescue
      { raw_body: response.body }
    end

    def update_identity!(parsed_response, mapped_data)
      updates = {
        raw_response: parsed_response
      }

      # Apply standard mapped fields safely
      %i[first_name last_name middle_name name administration_url external_id].each do |field|
        updates[field] = mapped_data[field] if mapped_data.key?(field)
      end

      # Merge custom attributes
      if mapped_data[:custom_attributes].present?
        updates[:custom_attributes] = mapped_data[:custom_attributes]
      end

      identity.update!(updates)
    end
  end
end
