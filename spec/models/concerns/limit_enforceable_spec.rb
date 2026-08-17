# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LimitEnforceable, type: :model do
  let(:plan) { create(:plan, limits: { 'users' => 5, 'conversations_monthly' => 100, 'channels' => -1 }) }
  let(:account) { create(:account, limits: { 'users' => { 'current' => 2 }, 'conversations_monthly' => { 'current' => 85 } }) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }

  describe '#within_limit?' do
    it 'returns true if current usage is below limit' do
      expect(account.within_limit?('users')).to be(true)
    end

    it 'returns true for unlimited resources (-1)' do
      expect(account.within_limit?('channels')).to be(true)
    end

    it 'returns false when usage reaches or exceeds limit' do
      account.update_column(:limits, { 'users' => { 'current' => 5 } })
      expect(account.within_limit?('users')).to be(false)
    end
  end

  describe '#limit_approaching?' do
    it 'returns true if usage exceeds the threshold' do
      expect(account.limit_approaching?('conversations_monthly', threshold: 0.8)).to be(true)
    end

    it 'returns false if usage is below threshold' do
      expect(account.limit_approaching?('users', threshold: 0.8)).to be(false)
    end
  end

  describe '#limit_reached?' do
    it 'respects strict mode' do
      account.update_column(:limits, { 'users' => { 'current' => 5 } })
      expect(account.limit_reached?('users', strict: true)).to be(true)
    end

    it 'applies 10% buffer for monthly resources in soft mode' do
      account.update_column(:limits, { 'conversations_monthly' => { 'current' => 105 } })
      # 105 is >= 100 but < 110 (100 * 1.1)
      expect(account.limit_reached?('conversations_monthly', strict: false)).to be(false)

      account.update_column(:limits, { 'conversations_monthly' => { 'current' => 112 } })
      expect(account.limit_reached?('conversations_monthly', strict: false)).to be(true)
    end
  end

  describe '#increment_usage! and #decrement_usage!' do
    it 'increments current resource count' do
      expect {
        account.increment_usage!('users')
      }.to change { account.current_usage('users') }.from(2).to(3)
    end

    it 'decrements current resource count and does not drop below zero' do
      account.decrement_usage!('users')
      expect(account.current_usage('users')).to eq(1)

      account.decrement_usage!('users')
      account.decrement_usage!('users')
      expect(account.current_usage('users')).to eq(0)
    end
  end

  describe '#reset_monthly_counters!' do
    it 'resets monthly resource counters to 0' do
      account.reset_monthly_counters!
      expect(account.current_usage('conversations_monthly')).to eq(0)
      expect(account.current_usage('messages_monthly')).to eq(0)
      expect(account.limits['last_reset_at']).to be_present
    end
  end
end
