# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExchangeRatesUpdaterWorker, type: :worker do
  describe '#perform' do
    let(:api_response_body) do
      {
        'result' => 'success',
        'rates' => {
          'USD' => 1.0,
          'EUR' => 0.92,
          'GBP' => 0.79
        }
      }
    end

    let(:http_response) do
      double('HTTParty::Response', success?: true, parsed_response: api_response_body)
    end

    it 'fetches rates and computes/saves cross-currency exchange rates' do
      expect(HTTParty).to receive(:get).with('https://open.er-api.com/v6/latest/USD').and_return(http_response)

      described_class.new.perform

      eur_to_gbp = ExchangeRate.find_by(from_currency: 'EUR', to_currency: 'GBP')
      expect(eur_to_gbp).to be_present
      # 0.79 / 0.92 = 0.858696
      expect(eur_to_gbp.rate).to eq((0.79 / 0.92).round(6))

      usd_to_eur = ExchangeRate.find_by(from_currency: 'USD', to_currency: 'EUR')
      expect(usd_to_eur).to be_present
      expect(usd_to_eur.rate).to eq(0.92)
    end

    it 'handles API failure gracefully' do
      failed_response = double('HTTParty::Response', success?: false)
      expect(HTTParty).to receive(:get).and_return(failed_response)

      expect { described_class.new.perform }.not_to raise_error
    end

    it 'rescues and logs unexpected exceptions' do
      expect(HTTParty).to receive(:get).and_raise(StandardError.new('Network timeout'))
      expect(Rails.logger).to receive(:error).with(/Exchange Rate Sync Failed: Network timeout/)

      expect { described_class.new.perform }.not_to raise_error
    end
  end
end
