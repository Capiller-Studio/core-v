# frozen_string_literal: true

module Billing
  class ChargeProcessor < ApplicationService
    attr_accessor :account, :amount, :currency, :description, :subscription

    def initialize(account:, amount:, currency: "USD", description: nil, subscription: nil)
      self.account = account
      self.amount = amount
      self.currency = currency
      self.description = description
      self.subscription = subscription
    end

    def call
      lock_key = ::RedisUtilities::Keys::CHARGE_LOCK % { account_id: account.id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          process_charge
        end
      end
    end

    private

    def process_charge
      remaining = amount
      wallet = account.wallet
      transactions = []

      # Step 1: Deduct from wallet first
      if wallet && wallet.balance.positive?
        wallet_deduction = [ wallet.balance, remaining ].min
        if wallet_deduction.positive?
          wallet.deduct!(wallet_deduction, description: "Payment: #{description}")
          remaining -= wallet_deduction

          transactions << create_transaction(
            amount: wallet_deduction,
            provider: :wallet,
            status: :completed,
            description: "Wallet deduction: #{description}"
          )
        end
      end

      # Step 2: Charge remaining via payment gateway
      if remaining.positive?
        result = charge_via_gateway(remaining)
        transactions << result[:transaction] if result[:transaction]
        raise(ActiveRecord::Rollback, "Payment failed") if result[:status] == :failed

        { status: result[:status], amount: amount, transactions: transactions, error: result[:error] }
      else
        { status: :completed, amount: amount, transactions: transactions }
      end
    end

    def charge_via_gateway(charge_amount)
      payment_method = account.default_payment_method
      unless payment_method
        transaction = create_transaction(
          amount: charge_amount,
          provider: PaymentGateway::Resolver.default_provider,
          status: :failed,
          description: "No payment method: #{description}"
        )
        return { status: :failed, error: "No payment method", transaction: transaction }
      end

      gateway = PaymentGateway::Resolver.for(account)
      result = gateway.charge(
        amount: charge_amount,
        currency:,
        description:,
        payment_method_id: payment_method.external_id
      )

      transaction = create_transaction(
        amount: charge_amount,
        provider: payment_method.provider,
        status: result[:status],
        external_id: result[:external_id],
        description:
      )

      { status: result[:status], amount: transaction.amount, transaction: transaction, error: result[:error] }
    end

    def create_transaction(amount:, provider:, status:, external_id: nil, description: nil)
      Transaction.create!(
        account:,
        subscription:,
        transaction_type: :charge,
        status:,
        amount:,
        currency:,
        provider:,
        external_id:,
        description:,
        data: {
          "line_items" => [ { "description" => description, "quantity" => 1, "unit_price" => amount.to_s, "amount" => amount.to_s } ],
          "period_start" => subscription&.current_period_start&.to_date&.to_s,
          "period_end" => subscription&.current_period_end&.to_date&.to_s
        }
      )
    end
  end
end
