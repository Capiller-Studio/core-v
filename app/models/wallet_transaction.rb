# frozen_string_literal: true

class WalletTransaction < ApplicationRecord
  belongs_to :account
  belongs_to :wallet
  belongs_to :reference, polymorphic: true, optional: true

  enum :transaction_type, { topup: 0, deduction: 1, refund: 2 }

  scope :recent, -> { order(created_at: :desc) }
  scope :credits, -> { where(transaction_type: [ :topup, :refund ]) }
  scope :debits, -> { where(transaction_type: :deduction) }
end
