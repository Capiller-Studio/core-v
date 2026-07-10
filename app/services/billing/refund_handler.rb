# frozen_string_literal: true

module Billing
  class RefundHandler < ApplicationService
    attr_accessor :transaction_id, :payment_intent_id

    def initialize(transaction_id: nil, payment_intent_id: nil)
      self.transaction_id = transaction_id
      self.payment_intent_id = payment_intent_id
    end

    def call
      transaction = find_transaction
      return unless transaction
      return if transaction.refunded?

      account = transaction.account
      lock_key = ::RedisUtilities::Keys::WALLET_LOCK % { account_id: account.id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        ActiveRecord::Base.transaction do
          transaction.mark_refunded!

          if transaction.topup?
            account.wallet.deduct!(
              transaction.amount,
              description: "Refunded top-up via #{transaction.provider.capitalize}",
              reference: transaction,
              force: true
            )
          end
        end
      end
    end

    private

    def find_transaction
      return Transaction.find_by(external_id: transaction_id) if transaction_id
      return Transaction.find_by(external_id: payment_intent_id) if payment_intent_id

      nil
    end
  end
end
