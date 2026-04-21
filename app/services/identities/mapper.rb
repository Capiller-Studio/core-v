# frozen_string_literal: true

module Identities
  class Mapper < ApplicationService
    attr_reader :identity_source, :raw_response

    def initialize(identity_source:, raw_response:)
      @identity_source = identity_source
      @raw_response = raw_response
    end

    def call
      mapping = identity_source.response_mapping
      return {} if mapping.blank?

      parsed_response = raw_response.is_a?(String) ? JSON.parse(raw_response) : raw_response

      result = {}
      
      # Extract standard fields specifically
      %w[first_name last_name middle_name name administration_url external_id].each do |field|
        if mapping[field].present?
          result[field.to_sym] = extract_value(parsed_response, mapping[field])
        end
      end

      # Extract custom attributes
      custom_mapping = mapping["custom_attributes"] || mapping["custom_fields"] || mapping
      if custom_mapping.is_a?(Hash)
        custom_attrs = {}
        custom_mapping.each do |key, path|
          # Skip standard fields if they are at the top level of custom_mapping
          next if %w[first_name last_name middle_name name administration_url external_id custom_attributes custom_fields].include?(key)
          
          value = extract_value(parsed_response, path)
          custom_attrs[key] = value unless value.nil?
        end
        result[:custom_attributes] = custom_attrs
      end

      result
    rescue JSON::ParserError
      {} # Return empty on invalid JSON response
    end

    private

    # Simple JSON path extractor: e.g., "data.customer.first_name" or "[0].name"
    def extract_value(data, path)
      return nil if path.blank?
      
      keys = path.to_s.split(".")
      current_value = data

      keys.each do |key|
        return nil if current_value.nil?

        if current_value.is_a?(Hash)
          # Indifferent access checking
          current_value = current_value[key] || current_value[key.to_sym]
        elsif current_value.is_a?(Array) && key.match?(/^\[\d+\]$/)
          # Array index e.g., "[0]"
          index = key.delete("[]").to_i
          current_value = current_value[index]
        else
          return nil
        end
      end

      current_value
    end
  end
end
