# frozen_string_literal: true

module Affiliates
  module Payouts
    module Wise
      class BatchFunder < ApplicationService
        attr_reader :payout_batch, :token, :attempts

        def initialize(payout_batch:, token: nil, attempts: 0)
          @payout_batch = payout_batch
          @token = token
          @attempts = attempts
        end

        def call
          return false if payout_batch.funded?
          return false if payout_batch.external_id.blank?

          response = HTTParty.post(
            fund_endpoint,
            headers: api_headers,
            body: { "type" => "BALANCE" }.to_json
          )
          
          record_api_response(response)

          if response.success?
            ActiveRecord::Base.transaction do
              payout_batch.update!(status: :funded, funded_at: Time.current)
              # rubocop:disable Rails/SkipsModelValidations
              payout_batch.payouts.update_all(status: :paid)
              # rubocop:enable Rails/SkipsModelValidations
            end
            return true
          end

          if response.headers["x-2fa-approval-result"]&.upcase == "REJECTED"
            new_token = response.headers["x-2fa-approval"]
            if attempts < 2
              return self.class.call(
                payout_batch: payout_batch,
                token: new_token,
                attempts: attempts + 1
              )
            end
          end

          payout_batch.update!(status: :failed)
          false
        rescue StandardError => e
          Rails.logger.error("Wise Batch Funder Exception [Batch ID: #{payout_batch.id}]: #{e.message}")
          false
        end

        private

        def record_api_response(response)
          ActiveRecord::Base.transaction do
            payout_batch.reload
            body = (JSON.parse(response.body) rescue {})
            api_logs = payout_batch.data["api_responses"] || {}
            api_logs["fund_#{attempts}"] = body
            payout_batch.update!(data: payout_batch.data.merge("api_responses" => api_logs))
          end
        end

        def fund_endpoint
          api_endpoint = Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_endpoint) || "https://api.transferwise.com"
          profile_id = Rails.application.credentials.dig(Rails.env.to_sym, :wise, :profile_id)
          URI.join(api_endpoint, "/v3/profiles/#{profile_id}/batch-groups/#{payout_batch.external_id}/payments").to_s
        end

        def api_headers
          base_headers = {
            "Authorization" => "Bearer #{Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_key)}",
            "Content-Type" => "application/json"
          }

          if token.present?
            signature = Affiliates::Payouts::Wise::Signer.call(token)
            base_headers.merge!(
              "x-2fa-approval" => token,
              "X-Signature" => signature
            )
          end
          base_headers
        end
      end
    end
  end
end
