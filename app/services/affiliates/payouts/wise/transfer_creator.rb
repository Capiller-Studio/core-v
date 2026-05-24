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
          return if payout.external_id.present? # Already created
          return unless validate_bank_data!

          quote_id = create_quote
          return unless quote_id

          account_id = create_account
          return unless account_id

          transfer_id = create_transfer(quote_id, account_id)
          return unless transfer_id

          payout.update!(external_id: transfer_id)
        rescue StandardError => e
          Rails.logger.error("Wise Transfer Creator Failed [Payout ID: #{payout.id}]: #{e.message}")
          # Raise the error so Sidekiq will retry it if appropriate
          raise e
        end

        private

        def validate_bank_data!
          bank_data = payout.profile.bank_account_data
          if bank_data.blank? || bank_data["iban"].blank? || bank_data["account_holder_name"].blank?
            payout.update!(status: :failed)
            payout.update!(data: payout.data.merge("error" => "Missing IBAN or Account Holder Name"))
            return false
          end
          true
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
          bank_data = payout.profile.bank_account_data
          
          # Optional address parsing
          details = { "iban" => bank_data["iban"] }
          if bank_data["address"].present?
            details["address"] = bank_data["address"] # Wise expects { "firstLine", "city", "postCode", "countryCode" }
          end
          
          response = HTTParty.post(
            "#{api_endpoint}/v1/accounts",
            headers: api_headers,
            body: {
              "currency" => payout.currency,
              "type" => "iban",
              "accountHolderName" => bank_data["account_holder_name"],
              "legalType" => "PRIVATE",
              "details" => details
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
          # Atomic DB update block to persist Wise interaction state safely
          ActiveRecord::Base.transaction do
            payout.reload # ensure latest state
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
