require 'rails_helper'

RSpec.describe Billing::RefundHandler do
  let(:account) { create(:account) }
  
  around do |example|
    Current.set(account: account) { example.run }
  end

  describe '#call' do
    context 'when transaction exists' do
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_refunded', status: :completed, transaction_type: :charge) }
      let(:service) { described_class.new(transaction_id: 'ch_refunded') }

      it 'refunds the transaction' do
        service.call
        expect(transaction.reload.status).to eq('refunded')
      end
    end

    context 'when transaction is a topup' do
      let!(:wallet) { create(:wallet, account: account, balance: 100.0) }
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_refund_topup', status: :completed, transaction_type: :topup, amount: 50.0, provider: 'stripe') }
      let(:service) { described_class.new(payment_intent_id: 'ch_refund_topup') }

      it 'deducts the refunded topup amount from the wallet' do
        expect { service.call }.to change { wallet.reload.balance }.by(-50.0)
      end
    end

    context 'when transaction is already refunded' do
      let!(:transaction) { create(:transaction, account: account, external_id: 'ch_refunded', status: :refunded) }
      let(:service) { described_class.new(transaction_id: 'ch_refunded') }

      it 'does nothing' do
        expect(transaction).not_to receive(:mark_refunded!)
        service.call
      end
    end
  end
end
