require 'rails_helper'

RSpec.describe PaymentGateway::Paddle do
  let(:account) { double('Account', id: 1, email: 'test@acc.com', name: 'Test Acc', billing_data: billing_data) }
  let(:billing_data) { {} }
  let(:service) { described_class.new(account) }
  let(:paddle_client) { double('PaddleClient') }

  before do
    allow(service).to receive(:paddle_client).and_return(paddle_client)
    allow(account).to receive(:update!)
    allow(service).to receive(:product_id).and_return('prod_123')
  end

  describe '#create_customer' do
    it 'creates customer and stores ID' do
      response = { "data" => { "id" => "ctm_123" } }
      expect(paddle_client).to receive(:post).with(
        "/customers",
        hash_including(email: 'test@acc.com', name: 'Test Acc')
      ).and_return(response)

      expect(account).to receive(:update!).with(billing_data: { "paddle_customer_id" => "ctm_123" })

      expect(service.create_customer).to eq(response["data"])
    end
  end

  describe '#charge' do
    context 'without customer id' do
      it 'returns error' do
        result = service.charge(amount: 100, currency: 'USD')
        expect(result[:status]).to eq(:failed)
        expect(result[:error]).to match(/No Paddle customer/)
      end
    end

    context 'with customer id' do
      let(:billing_data) { { 'paddle_customer_id' => 'ctm_123' } }

      it 'creates a transaction and returns status' do
        response = { "data" => { "id" => "txn_123", "status" => "completed" } }
        
        expect(paddle_client).to receive(:post).with(
          "/transactions",
          hash_including(
            customer_id: "ctm_123",
            items: [
              {
                price: {
                  description: "Charge desc",
                  unit_price: { amount: "10000", currency_code: "USD" },
                  product_id: "prod_123"
                },
                quantity: 1
              }
            ]
          )
        ).and_return(response)

        result = service.charge(amount: 100, currency: 'USD', description: 'Charge desc')
        expect(result).to eq(external_id: "txn_123", status: :completed, amount: 100)
      end
    end
  end

  describe '#refund' do
    it 'calls /adjustments' do
      response = { "data" => { "id" => "adj_123" } }
      
      expect(paddle_client).to receive(:post).with(
        "/adjustments",
        hash_including(
          transaction_id: "txn_123",
          action: "refund",
          amount: "5000"
        )
      ).and_return(response)

      result = service.refund(transaction_external_id: "txn_123", amount: 50)
      expect(result).to eq(external_id: "adj_123", status: :completed)
    end
  end
end
