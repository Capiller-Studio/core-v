# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::CreditManager do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  before do
    account.ai_wallet.grant_credits!(10, grant_type: :purchased, expires_at: 1.year.from_now)
  end

  describe '#call' do
    it 'deducts credits when balance is sufficient' do
      expect {
        described_class.call(
          account: account,
          action_type: 'draft_reply',
          model_used: 'gpt-5.6-luna',
          user: user,
          cost: 3
        )
      }.to change { account.ai_wallet.reload.available_balance }.from(10).to(7)
    end

    it 'raises AiInsufficientBalanceError when balance is insufficient on paid plan' do
      expect {
        described_class.call(
          account: account,
          action_type: 'draft_reply',
          model_used: 'gpt-5.6-luna',
          user: user,
          cost: 50
        )
      }.to raise_error(AiInsufficientBalanceError, 'AI credit balance is exhausted')
    end
  end

  describe '.refund!' do
    it 'adds refunded credits back to ai_wallet' do
      expect {
        described_class.refund!(account: account, amount: 5, action_type: 'draft_reply')
      }.to change { account.ai_wallet.reload.available_balance }.from(10).to(15)
    end
  end
end
