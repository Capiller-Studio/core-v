require 'rails_helper'

RSpec.describe Billing::SubscriptionCreator do
  let(:account) { create(:account) }
  let(:free_plan) { create(:plan, name: Plan::SYMBOLIC, base_price: 0, trial_days: 0, currency: 'USD', features: {}, limits: { 'users' => 1 }) }
  let(:paid_plan) { create(:plan, name: 'anabolic', base_price: 29.0, trial_days: 0, currency: 'USD', features: { 'monthly_ai_credits' => 100 }, limits: { 'users' => 5 }) }
  let(:trial_plan) { create(:plan, name: 'hyperbolic', base_price: 59.0, trial_days: 14, currency: 'USD', features: { 'monthly_ai_credits' => 200 }, limits: { 'users' => 10 }) }
  
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

    context 'when plan is not active' do
      let(:inactive_plan) { create(:plan, status: :archived) }
      let(:service) { described_class.new(account: account, plan: inactive_plan) }

      it 'raises an error' do
        expect { service.call }.to raise_error(/Plan is not available/)
      end
    end

    context 'when plan currency mismatch' do
      let(:euro_plan) { create(:plan, currency: 'EUR') }
      let(:service) { described_class.new(account: account, plan: euro_plan) }

      before { account.update!(currency: 'USD') }

      it 'raises an error' do
        expect { service.call }.to raise_error(/Plan currency mismatch/)
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
        expect(account.reload.limits['users']['max']).to eq(1)
      end
    end

    context 'when plan has a trial and account is eligible' do
      let(:service) { described_class.new(account: account, plan: trial_plan) }

      it 'creates a trialing subscription and grants AI credits' do
        expect(Billing::ChargeProcessor).not_to receive(:call)
        
        expect { service.call }.to change(Subscription, :count).by(1)
                               .and change(Ai::WalletTransaction, :count).by(1)
        
        subscription = Subscription.last
        expect(subscription.plan).to eq(trial_plan)
        expect(subscription.status).to eq('trialing')
        expect(subscription.trial_end_at).to be_present

        expect(account.reload.limits['users']['max']).to eq(10)

        # AI Wallet check
        wallet = account.ai_wallet
        expect(wallet.balance).to eq(200)
        grant = wallet.credit_grants.last
        expect(grant.grant_type).to eq('monthly_free')
        expect(grant.amount).to eq(200)
      end
    end

    context 'when plan has a trial but account is not eligible' do
      let(:service) { described_class.new(account: account, plan: trial_plan) }

      before do
        # Previous trialing subscription
        create(:subscription, account: account, status: :cancelled, plan: trial_plan, trial_end_at: 1.day.ago)
      end

      it 'charges and creates an active subscription' do
        expect(Billing::ChargeProcessor).to receive(:call).and_return({ status: :completed, transactions: [] })

        expect { service.call }.to change(Subscription, :count).by(1)

        subscription = account.subscriptions.active.last
        expect(subscription.status).to eq('active') # Skipped trial
      end
    end

    context 'when plan is paid without trial' do
      let(:service) { described_class.new(account: account, plan: paid_plan, quantity: 2) }

      it 'charges, creates subscription, and syncs limits' do
        transaction = create(:transaction, account: account, amount: 58.0, subscription: nil)
        
        expect(Billing::ChargeProcessor).to receive(:call).with(
          account: account,
          amount: 58.0,
          currency: 'USD',
          description: "Anabolic plan subscription (2 seats)"
        ).and_return({ status: :completed, transactions: [transaction] })
        
        expect { service.call }.to change(Subscription, :count).by(1)
                               .and change(Ai::WalletTransaction, :count).by(1)
        
        subscription = Subscription.last
        expect(subscription.plan).to eq(paid_plan)
        expect(subscription.status).to eq('active')
        expect(subscription.quantity).to eq(2)
        
        expect(transaction.reload.subscription_id).to eq(subscription.id)
        
        # Check limits synced
        expect(account.reload.limits['users']['max']).to eq(5)

        # AI Wallet check
        expect(account.ai_wallet.balance).to eq(100)
      end

      it 'raises an error if payment fails' do
        expect(Billing::ChargeProcessor).to receive(:call).and_return({ status: :failed, error: 'Declined' })
        
        expect { service.call }.to raise_error(/Payment failed/)
      end
    end
  end
end
