require 'rails_helper'

RSpec.describe Affiliates::CurrencyConverter do
  describe '#call' do
    let(:service) { described_class.new(from_currency: from_currency, to_currency: to_currency) }

    context 'when currencies are the same' do
      let(:from_currency) { 'USD' }
      let(:to_currency) { 'usd' }

      it 'returns 1.0' do
        expect(service.call).to eq(1.0)
      end
    end

    context 'when currencies differ' do
      let(:from_currency) { 'USD' }
      let(:to_currency) { 'EUR' }

      before do
        stub_const('ExchangeRate', double('ExchangeRateClass'))
      end

      it 'calculates rate with SPREAD_MARGIN if exchange rate is found' do
        rate_record = double('RateRecord', rate: 0.85)
        allow(ExchangeRate).to receive(:find_by).with(from_currency: 'USD', to_currency: 'EUR').and_return(rate_record)

        # Base rate = 0.85, spread = 2.5% = 0.025
        # 0.85 * (1.0 - 0.025) = 0.85 * 0.975 = 0.82875
        expected_rate = (0.85 * (1.0 - 0.025)).round(6)
        
        expect(service.call).to eq(expected_rate)
      end

      it 'returns 1.0 if exchange rate is missing' do
        allow(ExchangeRate).to receive(:find_by).and_return(nil)
        
        expect(service.call).to eq(1.0)
      end
    end
  end
end
