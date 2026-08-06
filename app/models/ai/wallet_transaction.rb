# frozen_string_literal: true

module Ai
  class WalletTransaction < ApplicationRecord
    belongs_to :account
    belongs_to :wallet, class_name: "Ai::Wallet", foreign_key: "ai_wallet_id"
    belongs_to :user, optional: true

    enum :transaction_type, { topup: 0, deduction: 1, refund: 2 }

    validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :balance_after, presence: true, numericality: { only_integer: true }

    scope :recent, -> { order(created_at: :desc) }
    scope :credits, -> { where(transaction_type: [ :topup, :refund ]) }
    scope :debits, -> { where(transaction_type: :deduction) }
  end
end
