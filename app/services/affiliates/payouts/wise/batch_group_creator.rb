# frozen_string_literal: true

module Affiliates
  module Payouts
    module Wise
      class BatchGroupCreator < ApplicationService
        attr_reader :payout_batch

        def initialize(payout_batch:)
          @payout_batch = payout_batch
        end

        def call
          return payout_batch.external_id if payout_batch.external_id.present?

          response = HTTParty.post(
            batch_group_endpoint,
            headers: api_headers,
            body: {
              "sourceCurrency" => "USD",
              "name" => payout_batch.name.presence || payout_batch.code || "Affiliate Batch #{payout_batch.id}"
            }.to_json
          )

          body = JSON.parse(response.body) rescue {}
          payout_batch.update!(data: payout_batch.data.merge("api_response" => body))

          if response.success?
            payout_batch.update!(external_id: body["id"])
            body["id"]
          else
            payout_batch.update!(status: :failed)
            Rails.logger.error("Wise Batch Group Creation Failed: #{response.body}")
            nil
          end
        end

        private

        def api_endpoint
          Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_endpoint) || "https://api.transferwise.com"
        end

        def profile_id
          Rails.application.credentials.dig(Rails.env.to_sym, :wise, :profile_id)
        end

        def batch_group_endpoint
          URI.join(api_endpoint, "/v3/profiles/#{profile_id}/batch-groups").to_s
        end

        def api_headers
          {
            "Authorization" => "Bearer #{Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_key)}",
            "Content-Type" => "application/json"
          }
        end
      end
    end
  end
end
