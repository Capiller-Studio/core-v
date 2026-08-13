# frozen_string_literal: true

module Ai
  class CreditTopup < ApplicationService
    # Price per 1,000 AI credits in each supported currency (in smallest unit / cents)
    PRICE_PER_1000_CREDITS = {
      "usd" => 15_00,   # $15.00
      "eur" => 15_00,   # €15.00
      "gbp" => 12_00,   # £12.00
      "krw" => 20_000   # ₩20,000
    }.freeze

    MIN_CREDITS = 1_000
    MAX_CREDITS = 100_000

    def initialize(account:, credits:)
      @account = account
      @credits = credits
      @currency = account.currency.downcase
    end

    def call
      validate!
      charge_and_credit!
    end

    private

    def validate!
      raise("Credits must be in multiples of 1,000") unless (@credits % 1_000).zero?
      raise("Minimum purchase is #{MIN_CREDITS} credits") if @credits < MIN_CREDITS
      raise("Maximum purchase is #{MAX_CREDITS} credits") if @credits > MAX_CREDITS
    end

    def charge_and_credit!
      amount_cents = price_for_credits
      amount = amount_cents / 100.0

      lock_key = ::RedisUtilities::Keys::WALLET_LOCK % { account_id: @account.id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          wallet = @account.wallet

          if wallet.sufficient_balance?(amount)
            # Deduct from existing wallet balance
            wallet.deduct!(amount, description: "AI Credits purchase: #{@credits} credits")
            
            # Record in Transaction for invoicing/history
            Transaction.create!(
              account: @account,
              transaction_type: :charge,
              status: :completed,
              amount: amount,
              currency: @currency,
              provider: :wallet,
              description: "AI Credits: #{@credits} credits"
            )
          else
            # Charge the card (follows Billing::WalletTopup pattern)
            payment_method = @account.default_payment_method
            raise("No payment method available") unless payment_method

            gateway = PaymentGateway::Resolver.for(@account)
            result = gateway.charge(
              amount: amount,
              currency: @currency,
              description: "AI Credits: #{@credits} credits",
              payment_method_id: payment_method.external_id
            )

            raise("Payment failed: #{result[:error]}") if result[:status] == :failed

            # Record in Transaction for invoicing
            Transaction.create!(
              account: @account,
              transaction_type: :charge,
              status: :completed,
              amount: amount,
              currency: @currency,
              provider: payment_method.provider,
              external_id: result[:external_id],
              description: "AI Credits: #{@credits} credits"
            )
          end

          # Credit the AI Wallet with a 1-year expiry grant
          @account.ai_wallet.grant_credits!(
            @credits,
            grant_type: :purchased,
            expires_at: 1.year.from_now,
            description: "Purchased #{@credits} AI credits"
          )
        end
      end
    end

    def price_for_credits
      rate = PRICE_PER_1000_CREDITS[@currency] || PRICE_PER_1000_CREDITS["usd"]
      (@credits / 1_000) * rate
    end
  end
end
