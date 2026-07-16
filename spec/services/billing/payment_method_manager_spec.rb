require 'rails_helper'

RSpec.describe Billing::PaymentMethodManager do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#add_stripe_method' do
    let(:gateway) { instance_double(PaymentGateway::Stripe) }
    let(:service) { described_class.new(account: account) }

    before do
      allow(PaymentGateway::Stripe).to receive(:new).with(account).and_return(gateway)
    end

    it 'adds a new Stripe payment method' do
      expect(gateway).to receive(:add_payment_method).with('tok_123').and_return({
        last_four: '4242',
        brand: 'Visa',
        expiry_month: 12,
        expiry_year: 2025,
        external_id: 'pm_123'
      })

      expect { service.add_stripe_method('tok_123') }.to change(PaymentMethod, :count).by(1)
      
      pm = PaymentMethod.last
      expect(pm.provider).to eq('stripe')
      expect(pm.last_four).to eq('4242')
      expect(pm.is_default).to be true
    end
  end

  describe '#handle_paddle_payment_method' do
    let(:service) { described_class.new(account: account) }
    let(:webhook_data) do
      {
        'data' => {
          'id' => 'pm_paddle_123',
          'payment' => {
            'method_details' => {
              'type' => 'card',
              'card' => { 'last4' => '1111', 'type' => 'Mastercard', 'expiry_month' => 10, 'expiry_year' => 2028 }
            }
          }
        }
      }
    end

    it 'creates a PaymentMethod from webhook data' do
      expect { service.handle_paddle_payment_method(webhook_data) }.to change(PaymentMethod, :count).by(1)
      
      pm = PaymentMethod.last
      expect(pm.provider).to eq('paddle')
      expect(pm.brand).to eq('Mastercard')
      expect(pm.last_four).to eq('1111')
    end
  end

  describe '#remove_method' do
    let(:service) { described_class.new(account: account) }
    let!(:pm1) { PaymentMethod.create!(account: account, is_default: true, provider: 'stripe', external_id: 'pm_1', status: :active, payment_type: :card) }
    let!(:pm2) { PaymentMethod.create!(account: account, is_default: false, provider: 'paddle', external_id: 'pm_2', status: :active, payment_type: :card) }
    let(:gateway) { instance_double(PaymentGateway::Stripe) }

    before do
      allow(PaymentGateway::Stripe).to receive(:new).with(account).and_return(gateway)
    end

    it 'removes method and promotes next default' do
      expect(gateway).to receive(:remove_payment_method).with('pm_1')
      
      service.remove_method(pm1)
      
      expect(pm1.reload.status).to eq('removed')
      expect(pm2.reload.is_default).to be true
    end
  end
end
