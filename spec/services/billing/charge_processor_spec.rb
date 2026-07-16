require 'rails_helper'

RSpec.describe Billing::ChargeProcessor do
  let(:account) { create(:account) }
  let(:wallet) { create(:wallet, account: account, balance: 50.0) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  before do
    allow(account).to receive(:wallet).and_return(wallet)
  end

  describe '#call' do
    context 'when wallet covers the full amount' do
      let(:service) { described_class.new(account: account, amount: 40.0, description: 'Test charge') }

      it 'deducts from wallet and creates a wallet transaction' do
        expect(wallet).to receive(:deduct!).with(40.0, description: 'Payment: Test charge').and_call_original
        
        expect { service.call }.to change(Transaction, :count).by(1)
        
        expect(wallet.reload.balance).to eq(10.0)
        
        transaction = Transaction.last
        expect(transaction.amount).to eq(40.0)
        expect(transaction.provider).to eq('wallet')
        expect(transaction.status).to eq('completed')
      end
    end

    context 'when wallet partially covers the amount' do
      let(:payment_method) { double('PaymentMethod', provider: 'stripe', external_id: 'pm_123') }
      let(:gateway) { double('Gateway') }
      let(:service) { described_class.new(account: account, amount: 80.0, description: 'Test charge') }

      before do
        allow(account).to receive(:default_payment_method).and_return(payment_method)
        allow(PaymentGateway::Resolver).to receive(:for).with(account).and_return(gateway)
      end

      it 'deducts from wallet and charges remainder via gateway' do
        expect(wallet).to receive(:deduct!).with(50.0, description: 'Payment: Test charge').and_call_original
        
        expect(gateway).to receive(:charge).with(
          amount: 30.0,
          currency: 'USD',
          description: 'Test charge',
          payment_method_id: 'pm_123'
        ).and_return({ status: :completed, external_id: 'ch_123' })
        
        expect { service.call }.to change(Transaction, :count).by(2)
        
        expect(wallet.reload.balance).to eq(0.0)
        
        transactions = Transaction.order(:created_at).last(2)
        expect(transactions[0].provider).to eq('wallet')
        expect(transactions[0].amount).to eq(50.0)
        
        expect(transactions[1].provider).to eq('stripe')
        expect(transactions[1].amount).to eq(30.0)
        expect(transactions[1].external_id).to eq('ch_123')
      end

      it 'rolls back if gateway charge fails' do
        expect(gateway).to receive(:charge).and_return({ status: :failed, external_id: 'ch_123', error: 'Declined' })
        
        expect { service.call }.not_to change(Transaction, :count)
      end
    end

    context 'when no payment method is available' do
      let(:service) { described_class.new(account: account, amount: 80.0) }

      before do
        allow(account).to receive(:default_payment_method).and_return(nil)
        allow(PaymentGateway::Resolver).to receive(:default_provider).and_return('stripe')
      end

      it 'fails and creates no transaction due to rollback' do
        expect { service.call }.not_to change(Transaction, :count)
      end
    end
  end
end
