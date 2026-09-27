# frozen_string_literal: true

module Billing
  class ChargeProcessor < ApplicationService
    attr_accessor :account, :amount, :currency, :description, :subscription, :data

    def initialize(account:, amount:, currency: "USD", description: nil, subscription: nil, data: {})
      self.account = account
      self.amount = amount
      self.currency = currency
      self.description = description
      self.subscription = subscription
      self.data = data
    end

    def call
      lock_key = ::RedisUtilities::Keys::CHARGE_LOCK % { account_id: account.id }

      outcome = ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          process_charge
        end
      end

      if outcome.is_a?(Hash) && outcome[:status] == :completed
        log_success(outcome[:transactions])
      else
        err = outcome.is_a?(Hash) ? outcome[:error] : "Payment failed"
        log_failure(err)
        outcome = { status: :failed, amount: amount, error: err } unless outcome.is_a?(Hash)
      end

      outcome
    end

    private

    def log_success(txns)
      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::BILLING_PAYMENT_SUCCEEDED,
        level: :info,
        account: account,
        message: "Payment succeeded for #{description}: #{amount} #{currency}",
        payload: {
          amount: amount.to_f,
          currency: currency,
          subscription_id: subscription&.id,
          transactions: Array(txns).map { |t| { id: t.id, amount: t.amount.to_f, provider: t.provider } }
        }
      )
    rescue StandardError => e
      Rails.logger.error("[ChargeProcessor] Failed to log success event: #{e.message}")
    end

    def log_failure(err_message)
      SystemLogs::Logger.call(
        event_key: SystemLogs::EventKeys::BILLING_PAYMENT_FAILED,
        level: :error,
        account: account,
        message: "Payment failed for #{description}: #{err_message}",
        payload: {
          amount: amount.to_f,
          currency: currency,
          subscription_id: subscription&.id,
          error: err_message
        }
      )
    rescue StandardError => e
      Rails.logger.error("[ChargeProcessor] Failed to log failure event: #{e.message}")
    end

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
            description: description
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
          description: description
        )
        return { status: :failed, error: "No payment method", transaction: transaction }
      end

      gateway = PaymentGateway::Resolver.for(account)
      result = gateway.charge(
        amount: charge_amount,
        currency:,
        description: I18n.t(description, **data.symbolize_keys, default: description.to_s),
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
        }.merge(data.deep_stringify_keys)
      )
    end
  end
end
