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

      it 'does not create duplicate notifications if already notified within 3 days' do
        account.with_shard do
          Notification.create!(
            account: account,
            user: owner_user,
            resource: expiring_subscription,
            event: :trial_expiring
          )
        end

        expect {
          described_class.new.perform
        }.not_to change { Notification.where(account: account, event: :trial_expiring).count }
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

      it 'downgrades, cancels, and logs BILLING_TRIAL_EXPIRED when no payment method and insufficient wallet' do
        expect(Billing::SubscriptionCanceller).to receive(:call).with(
          subscription: ended_subscription,
          immediate: true
        )
        expect(SystemLogs::Logger).to receive(:call).with(
          hash_including(
            event_key: SystemLogs::EventKeys::BILLING_TRIAL_EXPIRED,
            level: :warn,
            account: account
          )
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
        expect(SystemLogs::Logger).to receive(:call).with(
          hash_including(
            event_key: SystemLogs::EventKeys::BILLING_TRIAL_CONVERTED,
            level: :info,
            account: account
          )
        )

        described_class.new.perform

        ended_subscription.reload
        expect(ended_subscription.status).to eq('active')
      end

      it 'converts trial to active using wallet balance when payment method is nil but wallet covers total_price' do
        wallet = account.wallet || create(:wallet, account: account)
        wallet.update!(balance: 1000.0)
        allow(account).to receive(:default_payment_method).and_return(nil)
        allow(Subscription).to receive(:where).and_call_original
        allow_any_instance_of(Subscription).to receive(:account).and_return(account)

        expect(Billing::ChargeProcessor).to receive(:call).with(
          account: account,
          amount: ended_subscription.total_price,
          currency: account.currency,
          description: "#{ended_subscription.plan.name.capitalize} plan — trial conversion",
          subscription: ended_subscription
        ).and_return({ status: :completed })

        expect(SystemLogs::Logger).to receive(:call).with(
          hash_including(
            event_key: SystemLogs::EventKeys::BILLING_TRIAL_CONVERTED,
            level: :info,
            account: account
          )
        )

        described_class.new.perform

        ended_subscription.reload
        expect(ended_subscription.status).to eq('active')
      end

      it 'rescues unexpected errors and logs SYSTEM_WORKER_FAILED to SystemLogs::Logger' do
        allow_any_instance_of(described_class).to receive(:expire_trial).and_raise(StandardError.new('Unexpected DB error'))
        expect(SystemLogs::Logger).to receive(:call).with(
          hash_including(
            event_key: SystemLogs::EventKeys::SYSTEM_WORKER_FAILED,
            level: :error
          )
        )

        described_class.new.perform
      end
    end
  end
end
