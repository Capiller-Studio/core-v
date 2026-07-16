require 'rails_helper'

RSpec.describe Affiliates::Commissions::Refunder do
  let(:transaction) { double('Transaction', id: 'txn_123', amount: 100.0) }
  let(:commission) do 
    double('Commission', 
      id: 1, 
      affiliate_profile_id: 'prof_1', 
      affiliate_referral_id: 'ref_1',
      transaction_record_id: 'txn_123',
      original_amount: 20.0,
      original_currency: 'USD',
      exchange_rate: 1.0,
      amount: 20.0,
      currency: 'USD'
    ) 
  end

  before do
    stub_const('Affiliate::Commission', double('CommissionClass'))
    allow(Affiliate::Commission).to receive(:find_by).with(transaction_record_id: 'txn_123').and_return(commission)
    
    allow(commission).to receive(:pending?).and_return(false)
    allow(commission).to receive(:available?).and_return(false)
    allow(commission).to receive(:paid?).and_return(false)
  end

  describe '#call' do
    context 'when commission is pending or available' do
      before { allow(commission).to receive(:pending?).and_return(true) }

      context 'when full refund' do
        let(:service) { described_class.new(transaction: transaction) }

        it 'voids the commission' do
          expect(commission).to receive(:voided!)
          service.call
        end
      end

      context 'when partial refund' do
        let(:service) { described_class.new(transaction: transaction, refund_amount: 50.0) }

        it 'creates a negative adjustment commission' do
          allow(commission).to receive(:status).and_return(:pending)
          
          expect(Affiliate::Commission).to receive(:create!).with(
            hash_including(
              commission_type: :refund,
              original_amount: -10.0,
              amount: -10.0,
              status: :pending
            )
          )
          
          service.call
        end
      end
    end

    context 'when commission is paid' do
      before { allow(commission).to receive(:paid?).and_return(true) }
      let(:service) { described_class.new(transaction: transaction) }

      it 'creates a negative adjustment commission with available status' do
        expect(Affiliate::Commission).to receive(:create!).with(
          hash_including(
            commission_type: :refund,
            original_amount: -20.0,
            amount: -20.0,
            status: :available
          )
        )
        
        service.call
      end
    end
  end
end
