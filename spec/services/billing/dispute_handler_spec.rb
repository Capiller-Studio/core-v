require 'rails_helper'

RSpec.describe Billing::DisputeHandler do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when transaction exists' do
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_disputed', status: :completed, transaction_type: :charge) }
      let(:service) { described_class.new(transaction_id: 'ch_disputed') }

      it 'fails the transaction and suspends account' do
        service.call
        
        expect(transaction.reload.status).to eq('failed')
        expect(account.reload.status).to eq('suspended')
      end
    end

    context 'when transaction is a topup' do
      let!(:wallet) { create(:wallet, account: account, balance: 100.0) }
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_disputed_topup', status: :completed, transaction_type: :topup, amount: 50.0, provider: 'stripe') }
      let(:service) { described_class.new(payment_intent_id: 'ch_disputed_topup') }

      it 'deducts the topup amount from the wallet' do
        expect { service.call }.to change { wallet.reload.balance }.by(-50.0)
      end
    end

    context 'when transaction is already failed' do
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_disputed', status: :failed) }
      let(:service) { described_class.new(transaction_id: 'ch_disputed') }

      it 'does nothing' do
        service.call
        expect(account.reload.status).not_to eq('suspended')
      end
    end
  end
end
