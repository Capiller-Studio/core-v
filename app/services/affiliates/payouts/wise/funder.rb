# frozen_string_literal: true

module Affiliates
  module Payouts
    module Wise
      class Funder < ApplicationService
        attr_reader :payout, :token, :attempts

        def initialize(payout:, token: nil, attempts: 0)
          @payout = payout
          @token = token
          @attempts = attempts
        end

        def call
          return false if payout.paid?
          return false if payout.external_id.blank?

          lock_key = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: payout.affiliate_profile_id)

          ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
            payout.reload
            return false if payout.paid?

            response = HTTParty.post(
              fund_endpoint,
              headers: api_headers,
              body: { "type" => "BALANCE" }.to_json
            )

            record_api_response(response)

            if response.success?
              payout.update!(status: :paid)
              Affiliates::Payouts::InvoiceWorker.perform_async(payout.id)
              return true
            end

            if response.headers["x-2fa-approval-result"]&.upcase == "REJECTED"
              new_token = response.headers["x-2fa-approval"]
              if attempts < 2
                return self.class.call(
                  payout: payout,
                  token: new_token,
                  attempts: attempts + 1
                )
              end
            end

            payout.update!(status: :failed)
            false
          end
        rescue StandardError => e
          Rails.logger.error("Wise Funder Exception [Payout ID: #{payout&.id}]: #{e.message}")
          payout&.update!(status: :failed)
          false
        end

        private

        def record_api_response(response)
          ActiveRecord::Base.transaction do
            payout.reload
            body = (JSON.parse(response.body) rescue {})
            api_logs = payout.data["api_responses"] || {}
            api_logs["fund_#{attempts}"] = body
            payout.update!(data: payout.data.merge("api_responses" => api_logs))
          end
        end

        def fund_endpoint
          api_endpoint = Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_endpoint) || "https://api.transferwise.com"
          profile_id = Rails.application.credentials.dig(Rails.env.to_sym, :wise, :profile_id)
          URI.join(api_endpoint, "/v3/profiles/#{profile_id}/transfers/#{payout.external_id}/payments").to_s
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
