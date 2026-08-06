# frozen_string_literal: true

module Ai
  class CreditGrant < ApplicationRecord
    belongs_to :wallet, class_name: "Ai::Wallet", foreign_key: "ai_wallet_id"

    enum :grant_type, { monthly_free: 0, purchased: 1, promotion: 2, refund: 3 }

    validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
    validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :expires_at, presence: true

    scope :active, -> { where("balance > 0 AND expires_at > ?", Time.current) }
    scope :expiring_first, -> { order(expires_at: :asc) }

    def active?
      balance > 0 && expires_at > Time.current
    end

    def expired?
      expires_at <= Time.current
    end

    def exhausted?
      balance <= 0
    end
  end
end
