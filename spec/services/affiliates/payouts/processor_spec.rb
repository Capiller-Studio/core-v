require 'rails_helper'

RSpec.describe Affiliates::Payouts::Processor do
  let(:payout) { double('Affiliate::Payout', id: 'pay_1', affiliate_profile_id: 'prof_1', paid?: false) }
  let(:service) { described_class.new(payout: payout) }

  describe '#call' do
    before do
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
    end

    it 'returns nil if already paid' do
      allow(payout).to receive(:paid?).and_return(true)
      expect(service.call).to be_nil
    end

    context 'when provider is manual' do
      before do
        allow(payout).to receive(:provider).and_return('manual')
      end

      it 'updates payout status to paid' do
        expect(payout).to receive(:update!).with(status: :paid)
        service.call
      end
    end

    context 'when provider is wise' do
      before do
        allow(payout).to receive(:provider).and_return('wise')
        stub_const('Affiliates::Wise::TransferWorker', double('TransferWorker'))
      end

      it 'updates status to processing and queues worker' do
        expect(payout).to receive(:update!).with(status: :processing)
        expect(Affiliates::Wise::TransferWorker).to receive(:perform_async).with('pay_1')
        
        service.call
      end
    end

    context 'on error' do
      before do
        allow(payout).to receive(:provider).and_return('manual')
      end

      it 'marks payout as failed and returns nil' do
        allow(payout).to receive(:update!).with(status: :paid).and_raise(StandardError.new('DB Error'))
        expect(payout).to receive(:update!).with(status: :failed)
        
        expect(service.call).to be_nil
      end
    end
  end
end
