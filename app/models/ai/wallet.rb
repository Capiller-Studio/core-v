# frozen_string_literal: true

module Ai
  class Wallet < ApplicationRecord
    belongs_to :account

    has_many :wallet_transactions, class_name: "Ai::WalletTransaction", foreign_key: "ai_wallet_id", dependent: :destroy
    has_many :credit_grants, class_name: "Ai::CreditGrant", foreign_key: "ai_wallet_id", dependent: :destroy

    validates :account_id, uniqueness: true
    validates :balance, presence: true, numericality: { only_integer: true }

    def available_balance
      credit_grants.active.sum(:balance)
    end

    def sufficient_balance?(amount)
      available_balance >= amount
    end

    def deduct!(amount, action_type:, model_used:, user: nil, description: nil, data: {}, force: false)
      ActiveRecord::Base.transaction do
        locked = self.class.lock.find(id)
        
        if !force && locked.available_balance < amount
          raise(AiInsufficientBalanceError, "Insufficient AI credits")
        end

        remaining_to_deduct = amount

        locked.credit_grants.active.expiring_first.lock("FOR UPDATE").each do |grant|
          break if remaining_to_deduct <= 0

          deduct_from_grant = [grant.balance, remaining_to_deduct].min
          grant.update!(balance: grant.balance - deduct_from_grant)
          remaining_to_deduct -= deduct_from_grant
        end

        locked.update!(balance: locked.available_balance)
        reload

        record_transaction(:deduction, amount, action_type:, model_used:, user:, description:, data: data)
      end

      self
    end

    def grant_credits!(amount, grant_type:, expires_at:, description: nil, data: {})
      ActiveRecord::Base.transaction do
        locked = self.class.lock.find(id)
        
        locked.credit_grants.create!(
          amount: amount,
          balance: amount,
          grant_type: grant_type,
          expires_at: expires_at,
          description: description,
          data: data
        )

        locked.update!(balance: locked.available_balance)
        reload

        record_transaction(:topup, amount, description:, data: data)
      end

      self
    end

    def refund!(amount, description: nil, data: {})
      ActiveRecord::Base.transaction do
        locked = self.class.lock.find(id)
        
        locked.credit_grants.create!(
          amount: amount,
          balance: amount,
          grant_type: :refund,
          expires_at: 1.year.from_now,
          description: description || "Refund",
          data: data
        )

        locked.update!(balance: locked.available_balance)
        reload

        record_transaction(:refund, amount, description: description, data: data)
      end

      self
    end

    private

    def record_transaction(type, amount, action_type: nil, model_used: nil, user: nil, description: nil, data: {})
      wallet_transactions.create!(
        account: account,
        user: user,
        transaction_type: type,
        amount: amount,
        balance_after: balance,
        action_type: action_type,
        model_used: model_used,
        description: description,
        data: data
      )
    end
  end
end

class AiInsufficientBalanceError < StandardError; end
