require 'rails_helper'

RSpec.describe PaymentGateway::Stripe do
  let(:account) { double('Account', id: 'acc-1', email: 'test@acc.com', name: 'Test Acc', billing_data: billing_data) }
  let(:billing_data) { {} }
  let(:service) { described_class.new(account) }

  before do
    allow(account).to receive(:update!)
  end

  describe '#create_customer' do
    let(:customer_mock) { double('Stripe::Customer', id: 'cus_123') }

    it 'creates a customer and stores the id' do
      expect(::Stripe::Customer).to receive(:create).with(
        email: 'test@acc.com',
        name: 'Test Acc',
        metadata: { account_id: 'acc-1' }
      ).and_return(customer_mock)

      expect(account).to receive(:update!).with(billing_data: { "stripe_customer_id" => "cus_123" })

      expect(service.create_customer).to eq(customer_mock)
    end
  end

  describe '#charge' do
    context 'without a customer id' do
      it 'returns failed status' do
        result = service.charge(amount: 100, currency: 'USD')
        expect(result).to be_nil
      end
    end

    context 'with a customer id' do
      let(:billing_data) { { 'stripe_customer_id' => 'cus_123' } }
      let(:intent_mock) { double('Stripe::PaymentIntent', id: 'pi_123', status: 'succeeded') }

      it 'creates a payment intent and returns success' do
        expect(::Stripe::PaymentIntent).to receive(:create).with(
          amount: 10000,
          currency: 'usd',
          customer: 'cus_123',
          payment_method: 'pm_123',
          description: 'Charge desc',
          confirm: true,
          off_session: true,
          metadata: { account_id: 'acc-1' }
        ).and_return(intent_mock)

        result = service.charge(amount: 100, currency: 'USD', description: 'Charge desc', payment_method_id: 'pm_123')
        
        expect(result).to eq(external_id: 'pi_123', status: :completed, amount: 100)
      end

      it 'handles Stripe::CardError' do
        allow(::Stripe::PaymentIntent).to receive(:create).and_raise(::Stripe::CardError.new('Card declined', 'param'))

        result = service.charge(amount: 100, currency: 'USD', description: 'Charge desc', payment_method_id: 'pm_123')
        
        expect(result[:status]).to eq(:failed)
        expect(result[:error]).to eq('Card declined')
      end
    end
  end

  describe '#refund' do
    let(:refund_mock) { double('Stripe::Refund', id: 're_123') }

    it 'creates a refund via Stripe' do
      expect(::Stripe::Refund).to receive(:create).with({ payment_intent: 'pi_123', amount: 5000 }).and_return(refund_mock)
      
      result = service.refund(transaction_external_id: 'pi_123', amount: 50)
      expect(result).to eq(external_id: 're_123', status: :completed)
    end
  end
end
