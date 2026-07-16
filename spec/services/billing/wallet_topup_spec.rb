require 'rails_helper'

RSpec.describe Billing::WalletTopup do
  let(:account) { create(:account) }
  let(:wallet) { create(:wallet, account: account, balance: 0.0) }
  let(:payment_method) { double('PaymentMethod', provider: 'stripe', external_id: 'pm_123', display_name: 'Visa **** 4242') }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(account).to receive(:wallet).and_return(wallet)
    allow(account).to receive(:default_payment_method).and_return(payment_method)
  end

  describe '#call' do
    let(:gateway) { double('Gateway') }
    let(:service) { described_class.new(account: account, amount: 100.0, currency: 'USD') }

    before do
      allow(PaymentGateway::Resolver).to receive(:for).with(account).and_return(gateway)
    end

    it 'charges payment gateway and credits wallet' do
      expect(gateway).to receive(:charge).with(
        amount: 100.0,
        currency: 'USD',
        description: 'Wallet top-up',
        payment_method_id: 'pm_123'
      ).and_return({ status: :completed, external_id: 'ch_123' })
      
      expect(wallet).to receive(:credit!).with(100.0, hash_including(description: 'Top-up via Visa **** 4242')).and_call_original
      
      expect { service.call }.to change(Transaction, :count).by(1)
      
      transaction = Transaction.last
      expect(transaction.transaction_type).to eq('topup')
      expect(transaction.amount).to eq(100.0)
      expect(transaction.provider).to eq('stripe')
      
      expect(wallet.reload.balance).to eq(100.0)
    end

    it 'raises an error if charge fails' do
      expect(gateway).to receive(:charge).and_return({ status: :failed, error: 'Insufficient funds' })
      
      expect { service.call }.to raise_error(/Payment failed/)
      expect(wallet.reload.balance).to eq(0.0)
    end
    
    it 'raises an error if amount is not positive' do
      service = described_class.new(account: account, amount: -10.0)
      
      expect { service.call }.to raise_error(/Amount must be positive/)
    end
  end
end
