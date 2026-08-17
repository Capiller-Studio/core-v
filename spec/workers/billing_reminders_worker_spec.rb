# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BillingRemindersWorker, type: :worker do
  let(:system_mailer_class) do
    Class.new do
      def self.subscription_reminder(*); end
      def self.subscription_past_due(*); end
    end
  end

  before do
    stub_const('SystemMailer', system_mailer_class)
  end

  describe '#perform' do
    let(:account) { create(:account) }
    let(:plan) { create(:plan) }

    context 'trial reminders' do
      it 'sends reminder when trial ends in 3 days and account has no active payment methods' do
        subscription = create(:subscription, account: account, plan: plan, status: :trialing, trial_end_at: 3.days.from_now)
        mail_double = double('mail', deliver_later: true)
        expect(SystemMailer).to receive(:subscription_reminder).with(account).and_return(mail_double)

        described_class.new.perform
      end

      it 'sends reminder when trial ends in 1 day and account has no active payment methods' do
        subscription = create(:subscription, account: account, plan: plan, status: :trialing, trial_end_at: 1.day.from_now)
        mail_double = double('mail', deliver_later: true)
        expect(SystemMailer).to receive(:subscription_reminder).with(account).and_return(mail_double)

        described_class.new.perform
      end

      it 'does not send reminder if trial ends in 5 days' do
        create(:subscription, account: account, plan: plan, status: :trialing, trial_end_at: 5.days.from_now)
        expect(SystemMailer).not_to receive(:subscription_reminder)

        described_class.new.perform
      end
    end

    context 'past due reminders' do
      it 'sends past due reminder if period ended 1, 3, or 7 days ago' do
        subscription = create(:subscription, account: account, plan: plan, status: :past_due, current_period_end: 1.day.ago)
        mail_double = double('mail', deliver_later: true)
        expect(SystemMailer).to receive(:subscription_past_due).with(account).and_return(mail_double)

        described_class.new.perform
      end

      it 'does not send reminder if period ended 4 days ago' do
        create(:subscription, account: account, plan: plan, status: :past_due, current_period_end: 4.days.ago)
        expect(SystemMailer).not_to receive(:subscription_past_due)

        described_class.new.perform
      end
    end
  end
end
