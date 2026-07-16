require 'rails_helper'

RSpec.describe Affiliates::Payouts::Wise::Funder do
  let(:payout) do 
    double('Affiliate::Payout', 
      id: 1, 
      external_id: 'tr-123', 
      paid?: false, 
      data: {},
      reload: true
    )
  end
  let(:service) { described_class.new(payout: payout) }

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_endpoint).and_return('https://api.transferwise.com')
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :profile_id).and_return('prof-123')
    allow(Rails.application.credentials).to receive(:dig).with(:test, :wise, :api_key).and_return('secret-key')
  end

  describe '#call' do
    context 'when already paid or no external_id' do
      it 'returns false if paid' do
        allow(payout).to receive(:paid?).and_return(true)
        expect(service.call).to be(false)
      end

      it 'returns false if external_id is blank' do
        allow(payout).to receive(:external_id).and_return(nil)
        expect(service.call).to be(false)
      end
    end

    context 'when funding successfully' do
      let(:http_response) { double('HTTPResponse', success?: true, body: '{"success": true}', headers: {}) }

      before do
        allow(HTTParty).to receive(:post).and_return(http_response)
        allow(payout).to receive(:update!)
      end

      it 'calls API and updates payout' do
        expect(HTTParty).to receive(:post).with(
          'https://api.transferwise.com/v3/profiles/prof-123/transfers/tr-123/payments',
          headers: {
            'Authorization' => 'Bearer secret-key',
            'Content-Type' => 'application/json'
          },
          body: { "type" => "BALANCE" }.to_json
        )

        expect(payout).to receive(:update!).with(data: { "api_responses" => { "fund_0" => { "success" => true } } })
        expect(payout).to receive(:update!).with(status: :paid)

        expect(service.call).to be(true)
      end
    end

    context 'when 2FA is required' do
      let(:rejected_response) { double('HTTPResponse', success?: false, body: '{"error":"2fa"}', headers: { "x-2fa-approval-result" => "REJECTED", "x-2fa-approval" => "token123" }) }
      let(:success_response) { double('HTTPResponse', success?: true, body: '{"success":true}', headers: {}) }

      before do
        allow(payout).to receive(:update!)
        stub_const('Affiliates::Payouts::Wise::Signer', double('Signer'))
        allow(Affiliates::Payouts::Wise::Signer).to receive(:call).with("token123").and_return("sig123")
      end

      it 'retries with signed token' do
        expect(HTTParty).to receive(:post).with(
          anything,
          hash_including(headers: hash_not_including("x-2fa-approval" => "token123"))
        ).and_return(rejected_response)

        expect(HTTParty).to receive(:post).with(
          anything,
          hash_including(headers: hash_including("x-2fa-approval" => "token123", "X-Signature" => "sig123"))
        ).and_return(success_response)

        expect(service.call).to be(true)
      end
    end

    context 'when an error occurs' do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new('Net error'))
      end

      it 'rescues and returns false' do
        expect(Rails.logger).to receive(:error).with(/Wise Funder Exception/)
        expect(service.call).to be(false)
      end
    end
  end
end
