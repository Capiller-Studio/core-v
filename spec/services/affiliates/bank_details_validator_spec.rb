require 'rails_helper'

RSpec.describe Affiliates::BankDetailsValidator do
  let(:user) { double('User', address: address) }
  let(:address) { double('Address', country: 'US') }
  let(:profile) { double('Affiliate::Profile', user: user, bank?: true, payment_details: payment_details, currency: currency) }
  let(:payment_details) { {} }
  let(:currency) { 'USD' }
  
  let(:service) { described_class.new(profile) }

  describe '#call' do
    context 'when not a bank method' do
      before { allow(profile).to receive(:bank?).and_return(false) }

      it 'returns false with error' do
        result = service.call
        expect(result.success?).to be false
        expect(result.error).to eq("Not a bank payment method")
      end
    end

    context 'when missing user address' do
      let(:address) { double('Address', country: nil) }

      it 'returns false with error' do
        result = service.call
        expect(result.success?).to be false
        expect(result.error).to eq("Missing User Address or Country Code")
      end
    end

    context 'when currency is EUR' do
      let(:currency) { 'EUR' }
      let(:payment_details) { { 'iban' => 'IE123', 'account_holder_name' => 'John Doe' } }

      it 'returns true if valid' do
        expect(service.call.success?).to be true
      end

      it 'returns false if missing details' do
        allow(profile).to receive(:payment_details).and_return({ 'iban' => 'IE123' })
        expect(service.call.success?).to be false
      end
    end

    context 'when currency is USD' do
      let(:currency) { 'USD' }
      let(:payment_details) { { 'routing_number' => '123', 'account_number' => '456', 'account_type' => 'checking', 'account_holder_name' => 'John Doe' } }

      it 'returns true if valid' do
        expect(service.call.success?).to be true
      end

      it 'returns false if missing details' do
        allow(profile).to receive(:payment_details).and_return({ 'routing_number' => '123' })
        expect(service.call.success?).to be false
      end
    end

    context 'when currency is GBP' do
      let(:currency) { 'GBP' }
      let(:payment_details) { { 'sort_code' => '123', 'account_number' => '456', 'account_holder_name' => 'John Doe' } }

      it 'returns true if valid' do
        expect(service.call.success?).to be true
      end
    end

    context 'when currency is KRW' do
      let(:currency) { 'KRW' }
      let(:payment_details) { { 'bank_code' => '123', 'account_number' => '456', 'account_holder_name' => 'John Doe' } }

      it 'returns true if valid' do
        expect(service.call.success?).to be true
      end
    end

    context 'when unsupported currency' do
      let(:currency) { 'CAD' }

      it 'returns false with error' do
        result = service.call
        expect(result.success?).to be false
        expect(result.error).to eq("Unsupported Currency: CAD")
      end
    end
  end
end
