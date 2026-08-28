# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_methods
#
#  id             :uuid             not null, primary key
#  brand          :string
#  data           :jsonb            not null
#  default_method :boolean          default(FALSE), not null
#  expiry_month   :integer
#  expiry_year    :integer
#  last_four      :string
#  payment_type   :integer          default("card"), not null
#  provider       :integer          default("stripe"), not null
#  status         :integer          default("active"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :uuid             not null
#  external_id    :string
#
# Indexes
#
#  index_payment_methods_on_account_id                    (account_id)
#  index_payment_methods_on_account_id_and_default_method (account_id,default_method)
#  index_payment_methods_on_external_id                   (external_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class PaymentMethod < ApplicationRecord
  belongs_to :account

  enum :provider, { stripe: 0, paddle: 1 }
  enum :payment_type, { card: 0, bank_account: 1, paypal: 2 }
  enum :status, { active: 0, expired: 1, removed: 2 }

  scope :active_methods, -> { where(status: :active) }
  scope :default_method, -> { where(default_method: true, status: :active) }

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
      account.payment_methods.where(default_method: true).update_all(default_method: false)
      # rubocop:enable Rails/SkipsModelValidations
      update!(default_method: true)
    end
  end
end
