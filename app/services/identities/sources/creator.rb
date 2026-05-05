# frozen_string_literal: true

require "liquid"

module Identities
  module Sources
    class Creator < ApplicationService
      attr_reader :account, :params, :source

      def initialize(account:, params:)
        @account = account
        @params = params
      end

      def call
        validate_liquid_syntax!

        ActiveRecord::Base.transaction do
          @source = account.identity_sources.create!(
            name: params[:name],
            source_url: params[:source_url],
            description: params[:description],
            source_type: :api,
            configurations: params[:configurations] || {},
            headers: params[:headers] || {},
            response_mapping: params[:response_mapping] || {},
            params: params[:query_params] || {}
          )
        end
        source
      rescue Liquid::SyntaxError => e
        errors.add(:base, "Invalid Liquid Syntax: #{e.message}")
        nil
      rescue ActiveRecord::RecordInvalid => e
        errors.add(:base, e.message)
        nil
      end

      private

      def validate_liquid_syntax!
        Liquid::Template.parse(params[:source_url].to_s)

        # Validate values in hashes
        (params[:headers] || {}).each_value { |val| Liquid::Template.parse(val.to_s) }
        (params[:query_params] || {}).each_value { |val| Liquid::Template.parse(val.to_s) }
      end
    end
  end
end
