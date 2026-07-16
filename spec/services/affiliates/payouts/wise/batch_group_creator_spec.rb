require 'rails_helper'

RSpec.describe Affiliates::Payouts::Wise::BatchGroupCreator do
  let(:payout_batch) { double('Affiliate::PayoutBatch', id: 1, name: 'Batch 1', data: {}) }
  let(:service) { described_class.new(payout_batch: payout_batch) }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_endpoint).and_return('https://api.transferwise.com')
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :profile_id).and_return('prof-123')
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_key).and_return('secret-key')
  end

  describe '#call' do
    context 'when external_id already exists' do
      before do
        allow(payout_batch).to receive(:external_id).and_return('existing-123')
      end

      it 'returns the existing external_id' do
        expect(service.call).to eq('existing-123')
      end
    end

    context 'when creating a new batch group' do
      let(:response_body) { { 'id' => 'new-123' }.to_json }
      let(:http_response) { double('HTTPResponse', success?: true, body: response_body) }

      before do
        allow(payout_batch).to receive(:external_id).and_return(nil)
        allow(payout_batch).to receive(:update!)

        allow(HTTParty).to receive(:post).and_return(http_response)
      end

      it 'calls HTTParty and updates payout batch' do
        expect(HTTParty).to receive(:post).with(
          'https://api.transferwise.com/v3/profiles/prof-123/batch-groups',
          headers: {
            'Authorization' => 'Bearer secret-key',
            'Content-Type' => 'application/json'
          },
          body: { 'sourceCurrency' => 'USD', 'name' => 'Batch 1' }.to_json
        )

        expect(payout_batch).to receive(:update!).with(data: { 'api_response' => { 'id' => 'new-123' } })
        expect(payout_batch).to receive(:update!).with(external_id: 'new-123')

        expect(service.call).to eq('new-123')
      end

      context 'when API call fails' do
        let(:http_response) { double('HTTPResponse', success?: false, body: '{"error": "bad"}') }

        it 'updates status to failed and logs error' do
          expect(payout_batch).to receive(:update!).with(data: { 'api_response' => { 'error' => 'bad' } })
          expect(payout_batch).to receive(:update!).with(status: :failed)
          
          expect(Rails.logger).to receive(:error).with(/Wise Batch Group Creation Failed: /)

          expect(service.call).to be_nil
        end
      end
    end
  end
end
