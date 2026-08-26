# frozen_string_literal: true

module Affiliates
  module Payouts
    module Wise
      class TransferCreator < ApplicationService
        attr_reader :payout

        def initialize(payout:)
          @payout = payout
        end

        def call
          return payout.external_id if payout.external_id.present?

          lock_key = format(::RedisUtilities::Keys::PAYOUT_LOCK, profile_id: payout.affiliate_profile_id)

          ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
            payout.reload
            return payout.external_id if payout.external_id.present?
            return unless validate_bank_data!

            quote_id = create_quote
            return unless quote_id

            account_id = create_account
            return unless account_id

            transfer_id = create_transfer(quote_id, account_id)
            return unless transfer_id

            payout.update!(external_id: transfer_id)
            transfer_id
          end
        rescue StandardError => e
          Rails.logger.error("Wise Transfer Creator Failed [Payout ID: #{payout.id}]: #{e.message}")
          raise(e)
        end

        private

        def validate_bank_data!
          result = Affiliates::BankDetailsValidator.call(payout.profile)
          unless result.success?
            fail_payout!(result.error)
            return false
          end
          true
        end

        def fail_payout!(reason)
          ActiveRecord::Base.transaction do
            payout.update!(status: :failed)
            payout.update!(data: payout.data.merge("error" => reason))
          end
        end

        def create_quote
          response = HTTParty.post(
            "#{api_endpoint}/v2/quotes",
            headers: api_headers,
            body: {
              "sourceCurrency" => payout.currency,
              "targetCurrency" => payout.currency,
              "targetAmount" => payout.amount,
              "profile" => profile_id
            }.to_json
          )

          record_api_response("quote", response)
          raise("Wise Quote failed: #{response.body}") unless response.success?

          JSON.parse(response.body)["id"]
        end

        def create_account
          profile = payout.profile
          payload = profile.wise_bank_details_payload

          response = HTTParty.post(
            "#{api_endpoint}/v1/accounts",
            headers: api_headers,
            body: {
              "currency" => payout.currency,
              "type" => payload[:type],
              "accountHolderName" => profile.payment_details["account_holder_name"],
              "legalType" => profile.payment_details["legal_type"] || "PRIVATE",
              "details" => payload[:details]
            }.to_json
          )

          record_api_response("account", response)
          raise("Wise Account creation failed: #{response.body}") unless response.success?

          JSON.parse(response.body)["id"]
        end

        def create_transfer(quote_id, account_id)
          if payout.payout_batch_id.present?
            create_batch_transfer(quote_id, account_id)
          else
            create_standalone_transfer(quote_id, account_id)
          end
        end

        def create_standalone_transfer(quote_id, account_id)
          response = HTTParty.post(
            "#{api_endpoint}/v1/transfers",
            headers: api_headers,
            body: {
              "targetAccount" => account_id,
              "quoteUuid" => quote_id,
              "customerTransactionId" => payout.id, # IDEMPOTENCY KEY
              "details" => { "reference" => "Affiliate Payout #{payout.code}" }
            }.to_json
          )

          record_api_response("transfer", response)
          raise("Wise Transfer failed: #{response.body}") unless response.success?

          JSON.parse(response.body)["id"]
        end

        def create_batch_transfer(quote_id, account_id)
          batch = payout.payout_batch
          raise("Payout Batch external_id missing") if batch.external_id.blank?

          endpoint = URI.join(api_endpoint, "/v3/profiles/#{profile_id}/batch-groups/#{batch.external_id}/transfers").to_s

          response = HTTParty.post(
            endpoint,
            headers: api_headers,
            body: {
              "targetAccount" => account_id,
              "quoteUuid" => quote_id,
              "customerTransactionId" => payout.id, # IDEMPOTENCY KEY
              "details" => { "reference" => "Affiliate Payout #{payout.code}" }
            }.to_json
          )

          record_api_response("transfer", response)
          raise("Wise Batch Transfer failed: #{response.body}") unless response.success?

          JSON.parse(response.body)["id"]
        end

        def record_api_response(step, response)
          ActiveRecord::Base.transaction do
            payout.reload
            body = (JSON.parse(response.body) rescue {})
            api_logs = payout.data["api_responses"] || {}
            api_logs[step] = body
            payout.update!(data: payout.data.merge("api_responses" => api_logs))
          end
        end

        def api_endpoint
          Rails.application.credentials.dig(Rails.env.to_sym, :wise, :api_endpoint) || "https://api.transferwise.com"
        end

        def profile_id
          Rails.application.credentials.dig(Rails.env.to_sym, :wise, :profile_id)
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
