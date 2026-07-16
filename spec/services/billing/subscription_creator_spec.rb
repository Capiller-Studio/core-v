require 'rails_helper'

RSpec.describe Billing::SubscriptionCreator do
  let(:account) { create(:account) }
  let(:free_plan) { create(:plan, name: Plan::SYMBOLIC, base_price: 0, trial_days: 0, currency: 'USD') }
  let(:paid_plan) { create(:plan, name: 'anabolic', base_price: 29.0, trial_days: 0, currency: 'USD') }
  let(:trial_plan) { create(:plan, name: 'hyperbolic', base_price: 59.0, trial_days: 14, currency: 'USD') }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when account already has active subscription' do
      let!(:subscription) { create(:subscription, account: account, status: :active, plan: paid_plan) }
      let(:service) { described_class.new(account: account, plan: paid_plan) }

      it 'raises an error' do
        expect { service.call }.to raise_error(/already has an active subscription/)
      end
    end

    context 'when plan is free' do
      let(:service) { described_class.new(account: account, plan: free_plan) }

      it 'creates an active subscription without charging' do
        expect(Billing::ChargeProcessor).not_to receive(:call)
        
        expect { service.call }.to change(Subscription, :count).by(1)
        
        subscription = Subscription.last
        expect(subscription.plan).to eq(free_plan)
        expect(subscription.status).to eq('active')
        expect(subscription.current_period_end).to be_nil
      end
    end

    context 'when plan has a trial and account is eligible' do
      let(:service) { described_class.new(account: account, plan: trial_plan) }

      it 'creates a trialing subscription' do
        expect(Billing::ChargeProcessor).not_to receive(:call)
        
        expect { service.call }.to change(Subscription, :count).by(1)
        
        subscription = Subscription.last
        expect(subscription.plan).to eq(trial_plan)
        expect(subscription.status).to eq('trialing')
        expect(subscription.trial_end_at).to be_present
      end
    end

    context 'when plan is paid without trial' do
      let(:service) { described_class.new(account: account, plan: paid_plan, quantity: 2) }

      it 'charges and creates an active subscription' do
        transaction = create(:transaction, account: account, amount: 58.0, subscription: nil)
        
        expect(Billing::ChargeProcessor).to receive(:call).with(
          account: account,
          amount: 58.0,
          currency: 'USD',
          description: "Anabolic plan subscription (2 seats)"
        ).and_return({ status: :completed, transactions: [transaction] })
        
        expect { service.call }.to change(Subscription, :count).by(1)
        
        subscription = Subscription.last
        expect(subscription.plan).to eq(paid_plan)
        expect(subscription.status).to eq('active')
        expect(subscription.quantity).to eq(2)
        
        expect(transaction.reload.subscription_id).to eq(subscription.id)
      end

      it 'raises an error if payment fails' do
        expect(Billing::ChargeProcessor).to receive(:call).and_return({ status: :failed, error: 'Declined' })
        
        expect { service.call }.to raise_error(/Payment failed/)
      end
    end
  end
end
