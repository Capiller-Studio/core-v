# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Billable, type: :model do
  let(:free_plan) { create(:plan, :free) }
  let(:paid_plan) { create(:plan, :paid) }
  let(:account) { create(:account) }

  describe '#subscribed? and #current_plan' do
    it 'returns false and on_free_plan? true when no active subscription' do
      expect(account.subscribed?).to be(false)
      expect(account.on_free_plan?).to be(true)
      expect(account.on_paid_plan?).to be(false)
    end

    it 'returns subscription plan when subscription is active' do
      create(:subscription, account: account, plan: paid_plan, status: :active)

      expect(account.subscribed?).to be(true)
      expect(account.current_plan).to eq(paid_plan)
      expect(account.on_paid_plan?).to be(true)
      expect(account.on_free_plan?).to be(false)
    end

    it 'identifies trialing status' do
      create(:subscription, account: account, plan: paid_plan, status: :trialing, trial_end_at: 14.days.from_now)

      expect(account.trialing?).to be(true)
      expect(account.subscribed?).to be(true)
    end
  end

  describe '#wallet and #wallet_balance' do
    it 'creates a wallet for the account on create' do
      expect(account.wallet).to be_present
      expect(account.wallet_balance).to eq(account.wallet.balance)
    end
  end

  describe '#default_payment_method' do
    it 'returns default payment method if present' do
      pm = create(:payment_method, account: account, is_default: true)
      expect(account.default_payment_method).to eq(pm)
    end
  end
end
