# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Channels
  module Whatsapp
    module CloudApi
      class TemplateFetcher < ApplicationService
        attr_accessor :whatsapp_channel

        MAX_TEMPLATES = 500

        def initialize(whatsapp_channel:)
          self.whatsapp_channel = whatsapp_channel
        end

        def call
          return [] if whatsapp_channel.business_account_id.blank?

          raw_templates = fetch_all_templates
          approved_templates = raw_templates.select { |t| t["status"] == "APPROVED" }

          whatsapp_channel.update_columns(
            message_templates: approved_templates,
            templates_synced_at: Time.current
          )

          approved_templates
        rescue StandardError => e
          Rails.logger.error("WhatsApp TemplateFetcher error for #{whatsapp_channel.business_account_id}: #{e.message}")
          []
        end

        private

        def fetch_all_templates
          templates = []
          url = "#{whatsapp_channel.business_account_endpoint}/message_templates"
          query = {
            limit: 100,
            fields: "name,status,category,language,components"
          }

          while url.present? && templates.size < MAX_TEMPLATES
            response = HTTParty.get(url, headers: whatsapp_channel.api_headers, query: query)
            if (response.respond_to?(:unauthorized?) && response.unauthorized?) || (response.respond_to?(:code) && response.code.to_i == 401)
              whatsapp_channel.authorization_error!
              break
            end
            break unless response.success?

            batch = response.parsed_response&.dig("data") || []
            templates.concat(batch)

            next_url = response.parsed_response&.dig("paging", "next")
            if next_url.present? && batch.present?
              url = next_url
              query = nil
            else
              break
            end
          end

          templates
        end
      end
    end
  end
end
