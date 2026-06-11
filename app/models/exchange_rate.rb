# == Schema Information
#
# Table name: exchange_rates
#
#  id            :uuid             not null, primary key
#  from_currency :string           not null
#  to_currency   :string           not null
#  rate          :decimal(10, 6)   not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_exchange_rates_on_created_at                     (created_at)
#  index_exchange_rates_on_from_currency_and_to_currency  (from_currency,to_currency) UNIQUE
#

# frozen_string_literal: true

class ExchangeRate < ApplicationRecord
  validates :from_currency, presence: true
  validates :to_currency, presence: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
end
