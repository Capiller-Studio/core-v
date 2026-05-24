# frozen_string_literal: true

class Transaction < ApplicationRecord
  include CodeGenerator.new(prefix: "INV", column: :code)

  belongs_to :account
  belongs_to :subscription, optional: true
  belongs_to :original_transaction, class_name: "Transaction", optional: true
  has_many :refunds, class_name: "Transaction", foreign_key: "original_transaction_id", dependent: :nullify

  enum :transaction_type, { charge: 0, refund: 1, topup: 2, credit: 3 }
  enum :status, { pending: 0, completed: 1, failed: 2, refunded: 3 }
  enum :provider, { stripe: 0, paddle: 1, wallet: 2 }

  has_one_attached :invoice_pdf

  after_commit :process_affiliate_commissions, on: [ :create, :update ]

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :completed) }
  scope :charges, -> { where(transaction_type: :charge) }
  scope :invoices, -> { charges.where(status: [ :completed, :pending ]) }

  # Line items stored in data jsonb
  # [{ description:, quantity:, unit_price:, amount: }]
  def line_items
    data["line_items"] || []
  end

  def line_items=(items)
    self.data = data.merge("line_items" => items)
  end

  def due_date
    data["due_date"]&.to_date
  end

  def due_date=(date)
    self.data = data.merge("due_date" => date.to_s)
  end

  def period_start
    data["period_start"]&.to_date
  end

  def period_end
    data["period_end"]&.to_date
  end

  def complete!
    update!(status: :completed)
  end

  def fail!
    update!(status: :failed)
  end

  def mark_refunded!
    update!(status: :refunded)
  end

  def invoice?
    charge?
  end

  def overdue?
    pending? && due_date.present? && due_date < Date.current
  end

  # Subtotal from line items
  def subtotal
    line_items.sum { |item| item["amount"].to_d }
  end

  private

  def process_affiliate_commissions
    # Evaluate uniformly across paddle, stripe, and native wallet systems generically!
    if (saved_change_to_status? || previous_changes.empty?) && completed? && charge?
      Affiliates::Commissions::Calculator.call(transaction: self)
    elsif saved_change_to_status? && refunded? && charge?
      Affiliates::Commissions::Refunder.call(transaction: self)
    end
  end
end
