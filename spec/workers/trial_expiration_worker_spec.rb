# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrialExpirationWorker, type: :worker do
  let(:plan) { create(:plan, :momentum) }
  let(:account) { create(:account) }
  let(:owner_user) { create(:user) }
  let!(:account_user) { create(:account_user, account: account, user: owner_user, owner: true) }

  describe '#perform' do
    context 'notifying accounts about expiring trial' do
      let!(:expiring_subscription) do
        create(:subscription,
          account: account,
          plan: plan,
          status: :trialing,
          trial_end_at: 3.days.from_now
        )
      end

      it 'creates a trial_expiring notification for the account owner' do
        expect {
          described_class.new.perform
        }.to change { Notification.where(account: account, event: :trial_expiring).count }.by(1)
      end
    end

    context 'expiring ended trials' do
      let!(:ended_subscription) do
        create(:subscription,
          account: account,
          plan: plan,
          status: :trialing,
          trial_end_at: 1.hour.ago
        )
      end

      it 'downgrades and cancels subscription when no default payment method is present' do
        expect(Billing::SubscriptionCanceller).to receive(:call).with(
          subscription: ended_subscription,
          immediate: true
        )

        described_class.new.perform

        ended_subscription.reload
        expect(ended_subscription.status).to eq('expired')
      end

      it 'converts trial to active and charges when default payment method exists' do
        allow(account).to receive(:default_payment_method).and_return(double('PaymentMethod'))
        allow(Subscription).to receive(:where).and_call_original
        allow_any_instance_of(Subscription).to receive(:account).and_return(account)

        expect(Billing::ChargeProcessor).to receive(:call).and_return({ status: :completed })

        described_class.new.perform

        ended_subscription.reload
        expect(ended_subscription.status).to eq('active')
      end
    end
  end
end
