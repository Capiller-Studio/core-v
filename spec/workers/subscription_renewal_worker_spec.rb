# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionRenewalWorker, type: :worker do
  let(:plan) { create(:plan, :momentum, features: { 'monthly_ai_credits' => 50 }) }
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  before do
    account.ai_wallet || Ai::Wallet.create!(account: account, balance: 0)
    allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
  end

  describe '#perform' do
    context 'renewing active subscriptions due for renewal' do
      let!(:subscription) do
        create(:subscription,
          account: account,
          plan: plan,
          status: :active,
          billing_cycle: :monthly,
          current_period_start: 1.month.ago,
          current_period_end: 1.hour.ago
        )
      end

      it 'charges account and updates billing periods on successful payment' do
        expect(Billing::ChargeProcessor).to receive(:call).with(
          account: account,
          amount: subscription.total_price,
          currency: account.currency,
          description: "#{plan.name.capitalize} plan renewal",
          subscription: subscription
        ).and_return({ status: :completed })

        described_class.new.perform

        subscription.reload
        expect(subscription.status).to eq('active')
        expect(subscription.current_period_end).to be > Time.current
      end

      it 'marks subscription past_due and creates failure notification on payment failure' do
        expect(Billing::ChargeProcessor).to receive(:call).and_return({ status: :failed })

        expect {
          described_class.new.perform
        }.to change { Notification.where(account: account, event: :payment_failed).count }.by(1)

        subscription.reload
        expect(subscription.status).to eq('past_due')
      end

      it 'handles MutexLockError gracefully when another process holds the lock' do
        allow(RedisUtilities::MutexHelpers).to receive(:with_lock).and_raise(MutexLockError.new('Locked'))
        expect(Billing::ChargeProcessor).not_to receive(:call)

        expect { described_class.new.perform }.not_to raise_error
      end
    end

    context 'processing scheduled cancellations' do
      let!(:cancelled_subscription) do
        create(:subscription,
          account: account,
          plan: plan,
          status: :active,
          cancelled_at: 1.day.ago,
          current_period_end: 1.hour.ago
        )
      end

      it 'calls Billing::SubscriptionCanceller with immediate: true' do
        expect(Billing::SubscriptionCanceller).to receive(:call).with(
          subscription: cancelled_subscription,
          immediate: true
        )

        described_class.new.perform
      end
    end
  end
end
