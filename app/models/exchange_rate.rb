# frozen_string_literal: true

class ExchangeRate < ApplicationRecord
  validates :from_currency, presence: true
  validates :to_currency, presence: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
end
