# frozen_string_literal: true

class PaymentMethod < ApplicationRecord
  belongs_to :account

  enum :provider, { stripe: 0, paddle: 1 }
  enum :payment_type, { card: 0, bank_account: 1, paypal: 2 }
  enum :status, { active: 0, expired: 1, removed: 2 }

  scope :active_methods, -> { where(status: :active) }
  scope :default_method, -> { where(is_default: true, status: :active) }

  validates :external_id, presence: true

  def display_name
    "#{brand&.capitalize} ****#{last_four}"
  end

  def expired?
    return false unless expiry_month && expiry_year

    Date.new(expiry_year, expiry_month, -1) < Date.current
  end

  def make_default!
    transaction do
      # rubocop:disable Rails/SkipsModelValidations
      account.payment_methods.where(is_default: true).update_all(is_default: false)
      # rubocop:enable Rails/SkipsModelValidations
      update!(is_default: true)
    end
  end
end
