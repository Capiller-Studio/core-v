require 'rails_helper'

RSpec.describe PaymentGateway::Resolver do
  describe '.for' do
    let(:account) { double('Account', billing_data: billing_data) }
    
    before do
      allow(Rails.application.credentials).to receive(:dig).with(:payment, :default_provider).and_return('stripe')
    end

    context 'when provider is stripe' do
      let(:billing_data) { { 'provider' => 'stripe' } }
      it 'returns a Stripe gateway instance' do
        expect(described_class.for(account)).to be_a(PaymentGateway::Stripe)
      end
    end

    context 'when provider is paddle' do
      let(:billing_data) { { 'provider' => 'paddle' } }
      it 'returns a Paddle gateway instance' do
        expect(described_class.for(account)).to be_a(PaymentGateway::Paddle)
      end
    end

    context 'when provider is missing' do
      let(:billing_data) { {} }
      it 'falls back to the default provider' do
        expect(described_class.for(account)).to be_a(PaymentGateway::Stripe)
      end
    end

    context 'when provider is unknown' do
      let(:billing_data) { { 'provider' => 'unknown' } }
      it 'raises an ArgumentError' do
        expect { described_class.for(account) }.to raise_error(ArgumentError, /Unknown payment provider: unknown/)
      end
    end
  end
end
