require 'rails_helper'

RSpec.describe Billing::CheckoutSessionCreator do
  let(:account) { create(:account) }
  let(:plan) { create(:plan, name: 'anabolic', base_price: 29.0) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    let(:gateway) { double('Gateway') }
    let(:service) { described_class.new(account: account, plan: plan, billing_cycle: :monthly) }

    before do
      allow(PaymentGateway::Resolver).to receive(:for).with(account).and_return(gateway)
      create(:account_user, account: account, user: create(:user))
    end

    context 'when provider is paddle' do
      before do
        allow(gateway).to receive(:provider_name).and_return('paddle')
        allow(gateway).to receive(:gateway_customer_id).and_return('cus_paddle_123')
        
        plan.define_singleton_method(:configurations) { { 'paddle' => { 'price_id_monthly' => 'pri_123' } } }
      end

      it 'returns paddle checkout configuration' do
        result = service.call
        
        expect(result[:provider]).to eq('paddle')
        expect(result[:customer_id]).to eq('cus_paddle_123')
        expect(result[:items]).to eq([{ price_id: 'pri_123', quantity: 1 }])
        expect(result[:custom_data][:plan_id]).to eq(plan.id)
      end
    end

    context 'when provider is stripe' do
      let(:stripe_session) { double('StripeSession', id: 'cs_test_123', url: 'https://checkout.stripe.com/...') }

      before do
        allow(gateway).to receive(:provider_name).and_return('stripe')
        allow(gateway).to receive(:gateway_customer_id).and_return('cus_stripe_123')
      end

      it 'creates a Stripe Checkout Session and returns its details' do
        expect(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(
            customer: 'cus_stripe_123',
            mode: 'subscription',
            line_items: [{
              price_data: hash_including(unit_amount: 2900),
              quantity: 1
            }],
            metadata: hash_including(plan_id: plan.id)
          )
        ).and_return(stripe_session)

        result = service.call
        
        expect(result[:provider]).to eq('stripe')
        expect(result[:session_id]).to eq('cs_test_123')
        expect(result[:checkout_url]).to eq('https://checkout.stripe.com/...')
      end
    end
  end
end
