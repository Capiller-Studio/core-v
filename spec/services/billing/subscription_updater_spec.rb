require 'rails_helper'

RSpec.describe Billing::SubscriptionUpdater do
  let(:account) { create(:account) }
  let(:plan1) { create(:plan, name: 'anabolic', base_price: 29.0, currency: 'USD') }
  let(:plan2) { create(:plan, name: 'hyperbolic', base_price: 59.0, currency: 'USD') }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when subscription is active and changing quantity' do
      let(:subscription) { create(:subscription, account: account, plan: plan1, quantity: 2, status: :active, current_period_start: 10.days.ago, current_period_end: 20.days.from_now) }
      let(:service) { described_class.new(subscription: subscription, new_quantity: 4) }

      before do
        allow(subscription).to receive(:total_price).and_return(58.0)
        allow(subscription).to receive(:total_days_in_cycle).and_return(30)
        allow(subscription).to receive(:remaining_days_in_cycle).and_return(20)
      end

      it 'charges prorated amount for extra seats' do
        # unused credit = (58.0 / 30) * 20 = 38.67
        # new total price = 29.0 * 4 = 116.0
        # new daily rate = 116.0 / 30 = 3.866
        # remaining charge = 3.866 * 20 = 77.33
        # net diff = 77.33 - 38.67 = 38.66

        expect(Billing::ChargeProcessor).to receive(:call).with(
          hash_including(amount: 38.66, description: "billing.events.added_seats")
        )
        
        service.call
        
        expect(subscription.reload.quantity).to eq(4)
      end
    end

    context 'when downgrading quantity' do
      let(:wallet) { create(:wallet, account: account, balance: 0.0) }
      let(:subscription) { create(:subscription, account: account, plan: plan1, quantity: 4, status: :active, current_period_start: 10.days.ago, current_period_end: 20.days.from_now) }
      let(:service) { described_class.new(subscription: subscription, new_quantity: 2) }

      before do
        allow(account).to receive(:wallet).and_return(wallet)
        allow(subscription).to receive(:total_price).and_return(116.0)
        allow(subscription).to receive(:total_days_in_cycle).and_return(30)
        allow(subscription).to receive(:remaining_days_in_cycle).and_return(20)
      end

      it 'credits wallet for unused seats' do
        # unused credit = (116.0 / 30) * 20 = 77.33
        # new total price = 29.0 * 2 = 58.0
        # new daily rate = 58.0 / 30 = 1.933
        # remaining charge = 1.933 * 20 = 38.67
        # net diff = 38.67 - 77.33 = -38.66

        expect(wallet).to receive(:credit!).with(38.66, description: "billing.events.removed_seats").and_call_original
        
        expect { service.call }.to change(Transaction, :count).by(1)
        
        expect(subscription.reload.quantity).to eq(2)
        expect(wallet.reload.balance).to eq(38.66)
        
        transaction = Transaction.last
        expect(transaction.transaction_type).to eq('refund')
        expect(transaction.amount).to eq(38.66)
      end
    end

    context 'when validation fails' do
      let(:subscription) { create(:subscription, account: account, plan: plan1, quantity: 2, status: :active) }
      let(:service) { described_class.new(subscription: subscription, new_quantity: 1) }

      before do
        allow(account).to receive(:users_count).and_return(3)
      end

      it 'raises an error if quantity is less than active users' do
        expect { service.call }.to raise_error(/cannot be less than currently active users/)
      end
    end
  end
end
