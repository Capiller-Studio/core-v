require 'rails_helper'

RSpec.describe Billing::SubscriptionCanceller do
  let(:account) { create(:account) }
  let(:plan) { create(:plan, name: 'hyperbolic', currency: 'USD') }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active, external_id: 'sub_123', provider: 'stripe') }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when immediate is false' do
      let(:service) { described_class.new(subscription: subscription, immediate: false) }

      it 'schedules cancellation' do
        service.call
        expect(subscription.reload.cancelled_at).to be_present
        expect(subscription.status).to eq('active') # remains active until period end typically
      end
    end

    context 'when immediate is true' do
      let(:service) { described_class.new(subscription: subscription, immediate: true) }
      let(:gateway) { double('Gateway') }
      let!(:free_plan) { create(:plan, name: Plan::SYMBOLIC, currency: 'USD') }

      before do
        allow(PaymentGateway::Resolver).to receive(:for).with(account).and_return(gateway)
        allow(gateway).to receive(:cancel_subscription)
      end

      it 'cancels at gateway, cancels subscription locally, and downgrades to free plan' do
        expect(gateway).to receive(:cancel_subscription).with('sub_123')
        
        expect { service.call }.to change(Subscription, :count).by(1) # Downgrades by creating a new subscription
        
        expect(subscription.reload.status).to eq('cancelled')
        
        new_sub = Subscription.order(:created_at).last
        expect(new_sub.plan).to eq(free_plan)
        expect(new_sub.status).to eq('active')
      end

      it 'handles gateway errors without failing' do
        expect(gateway).to receive(:cancel_subscription).and_raise(StandardError.new('Gateway error'))
        
        expect { service.call }.not_to raise_error
        expect(subscription.reload.status).to eq('cancelled')
      end
    end
  end
end
