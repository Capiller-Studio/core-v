# frozen_string_literal: true

module Billing
  class WalletTopup < ApplicationService
    attr_accessor :account, :amount, :currency

    def initialize(account:, amount:, currency: nil)
      self.account = account
      self.amount = amount
      self.currency = currency || account.currency
    end

    def call
      lock_key = RedisUtilities::Keys::WALLET_LOCK % { account_id: account.id }

      RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          process_topup
        end
      end
    end

    private

    def process_topup
      raise "Amount must be positive" unless amount.positive?

      payment_method = account.default_payment_method
      raise "No payment method available" unless payment_method

      gateway = PaymentGateway::Resolver.for(account)
      result = gateway.charge(
        amount:,
        currency:,
        description: "Wallet top-up",
        payment_method_id: payment_method.external_id
      )

      raise "Payment failed: #{result[:error]}" if result[:status] == :failed

      txn = Transaction.create!(
        account:,
        transaction_type: :topup,
        status: :completed,
        amount:,
        currency:,
        provider: payment_method.provider,
        external_id: result[:external_id],
        description: "Wallet top-up"
      )

      account.wallet.credit!(amount, description: "Top-up via #{payment_method.display_name}", reference: txn)

      txn
    end
  end
end
