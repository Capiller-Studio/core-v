# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :account

  has_many :wallet_transactions, dependent: :destroy

  validates :account_id, uniqueness: true

  def sufficient_balance?(amount)
    balance >= amount
  end

  # Atomic deduction inside a DB transaction
  def deduct!(amount, description: nil, reference: nil)
    ActiveRecord::Base.transaction do
      # Lock the row for update to prevent races
      locked = self.class.lock.find(id)
      raise InsufficientBalanceError, "Insufficient wallet balance" unless locked.balance >= amount

      new_balance = locked.balance - amount
      locked.update!(balance: new_balance)
      reload

      record_transaction(:deduction, -amount, description:, reference:)
    end

    self
  end

  # Atomic credit
  def credit!(amount, description: nil, reference: nil)
    ActiveRecord::Base.transaction do
      locked = self.class.lock.find(id)
      new_balance = locked.balance + amount
      locked.update!(balance: new_balance)
      reload

      record_transaction(:topup, amount, description:, reference:)
    end

    self
  end

  def refund!(amount, description: nil, reference: nil)
    credit!(amount, description: description || "Refund", reference:)
  end

  private

  def record_transaction(type, amount, description: nil, reference: nil)
    wallet_transactions.create!(
      account:,
      transaction_type: type,
      amount:,
      balance_after: balance,
      currency:,
      description:,
      reference:
    )
  end
end

class InsufficientBalanceError < StandardError; end
class ConcurrencyError < StandardError; end
