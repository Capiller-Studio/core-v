# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExchangeRate, type: :model do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:from_currency) }
    it { is_expected.to validate_presence_of(:to_currency) }
    it { is_expected.to validate_presence_of(:rate) }
    it { is_expected.to validate_numericality_of(:rate).is_greater_than(0) }
  end

  describe 'creation' do
    it 'creates a valid exchange rate record' do
      rate = create(:exchange_rate, from_currency: 'USD', to_currency: 'GBP', rate: 0.78)
      expect(rate).to be_persisted
      expect(rate.rate).to eq(0.78)
    end
  end
end
