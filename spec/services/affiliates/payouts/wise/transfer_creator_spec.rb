require 'rails_helper'

RSpec.describe Affiliates::Payouts::Wise::TransferCreator do
  let(:profile) do
    double('Affiliate::Profile',
      payment_details: { "account_holder_name" => "John Doe", "legal_type" => "PRIVATE" },
      wise_bank_details_payload: { type: "aba", details: { "routingNumber" => "123", "accountNumber" => "456" } }
    )
  end
  let(:payout_batch) { nil }
  let(:payout) do
    double('Affiliate::Payout',
      id: 1,
      code: 'PO123',
      external_id: nil,
      currency: 'USD',
      amount: 100.0,
      profile: profile,
      payout_batch_id: payout_batch ? 1 : nil,
      payout_batch: payout_batch,
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
    context 'when external_id already exists' do
      before do
        allow(payout).to receive(:external_id).and_return('tr-123')
      end

      it 'returns early' do
        expect(HTTParty).not_to receive(:post)
        service.call
      end
    end

    context 'when bank details are invalid' do
      before do
        stub_const('Affiliates::BankDetailsValidator', double('Validator'))
        allow(Affiliates::BankDetailsValidator).to receive(:call).with(profile).and_return(double(success?: false, error: 'Invalid ABA'))
        allow(payout).to receive(:update!)
      end

      it 'fails the payout' do
        expect(payout).to receive(:update!).with(status: :failed)
        expect(payout).to receive(:update!).with(data: { "error" => "Invalid ABA" })
        service.call
      end
    end

    context 'when bank details are valid' do
      before do
        stub_const('Affiliates::BankDetailsValidator', double('Validator'))
        allow(Affiliates::BankDetailsValidator).to receive(:call).with(profile).and_return(double(success?: true))
        allow(payout).to receive(:update!)
      end

      context 'and API calls succeed for standalone transfer' do
        let(:quote_response) { double('HTTPResponse', success?: true, body: '{"id":"quote-123"}') }
        let(:account_response) { double('HTTPResponse', success?: true, body: '{"id":"account-456"}') }
        let(:transfer_response) { double('HTTPResponse', success?: true, body: '{"id":"transfer-789"}') }

        it 'creates quote, account, and transfer' do
          expect(HTTParty).to receive(:post).with(
            'https://api.transferwise.com/v2/quotes',
            anything
          ).ordered.and_return(quote_response)
          
          expect(HTTParty).to receive(:post).with(
            'https://api.transferwise.com/v1/accounts',
            anything
          ).ordered.and_return(account_response)

          expect(HTTParty).to receive(:post).with(
            'https://api.transferwise.com/v1/transfers',
            hash_including(body: /"targetAccount":"account-456"/)
          ).ordered.and_return(transfer_response)

          allow(payout).to receive(:update!)
          expect(payout).to receive(:update!).with(external_id: 'transfer-789')
          service.call
        end
      end

      context 'and API calls succeed for batch transfer' do
        let(:payout_batch) { double('Affiliate::PayoutBatch', external_id: 'batch-bg-1') }
        
        let(:quote_response) { double('HTTPResponse', success?: true, body: '{"id":"quote-123"}') }
        let(:account_response) { double('HTTPResponse', success?: true, body: '{"id":"account-456"}') }
        let(:transfer_response) { double('HTTPResponse', success?: true, body: '{"id":"transfer-789"}') }

        it 'creates a batch transfer' do
          expect(HTTParty).to receive(:post).with('https://api.transferwise.com/v2/quotes', anything).ordered.and_return(quote_response)
          expect(HTTParty).to receive(:post).with('https://api.transferwise.com/v1/accounts', anything).ordered.and_return(account_response)

          expect(HTTParty).to receive(:post).with(
            'https://api.transferwise.com/v3/profiles/prof-123/batch-groups/batch-bg-1/transfers',
            hash_including(body: /"targetAccount":"account-456"/)
          ).ordered.and_return(transfer_response)

          allow(payout).to receive(:update!)
          expect(payout).to receive(:update!).with(external_id: 'transfer-789')
          service.call
        end
      end
    end
  end
end
