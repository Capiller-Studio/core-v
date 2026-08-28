# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::CreditTopup do
  let(:account) { create(:account, currency: 'USD') }

  describe 'validation' do
    it 'rejects credits not in multiples of 1,000' do
      expect {
        described_class.call(account: account, credits: 1500)
      }.to raise_error(RuntimeError, 'Credits must be in multiples of 1,000')
    end

    it 'rejects credits below minimum' do
      expect {
        described_class.call(account: account, credits: 0)
      }.to raise_error(RuntimeError, 'Minimum purchase is 1000 credits')
    end

    it 'rejects credits above maximum' do
      expect {
        described_class.call(account: account, credits: 200_000)
      }.to raise_error(RuntimeError, 'Maximum purchase is 100000 credits')
    end
  end

  describe '#call with wallet funds' do
    before do
      account.wallet.update!(balance: 50.0)
    end

    it 'deducts from wallet balance and grants AI credits' do
      expect {
        described_class.call(account: account, credits: 2000)
      }.to change { account.wallet.reload.balance }.by(-30.0)
       .and change { account.ai_wallet.reload.available_balance }.by(2000)
    end
  end

  describe '#call with credit card payment method' do
    let(:payment_method) { create(:payment_method, account: account, default_method: true) }
    let(:gateway) { instance_double(PaymentGateway::Stripe) }

    before do
      account.wallet.update!(balance: 0.0)
      payment_method
      allow(PaymentGateway::Resolver).to receive(:for).with(account).and_return(gateway)
    end

    it 'charges payment gateway and grants AI credits' do
      expect(gateway).to receive(:charge).with(
        amount: 15.0,
        currency: 'usd',
        description: 'AI Credits: 1000 credits',
        payment_method_id: payment_method.external_id
      ).and_return({ status: :success, external_id: 'ch_123' })

      expect {
        described_class.call(account: account, credits: 1000)
      }.to change { account.ai_wallet.reload.available_balance }.by(1000)
    end
  end
end
