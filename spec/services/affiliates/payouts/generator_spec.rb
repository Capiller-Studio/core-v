require 'rails_helper'

RSpec.describe Affiliates::Payouts::Generator do
  let(:profile) { double('Affiliate::Profile', id: 'prof_1', currency: 'USD') }
  let(:service) { described_class.new(profile: profile) }

  describe '#call' do
    before do
      allow(profile).to receive(:payouts_enabled?).and_return(true)
      allow(profile).to receive(:valid_bank_details?).and_return(true)
      allow(::RedisUtilities::MutexHelpers).to receive(:with_lock).and_yield
    end

    context 'when validations fail' do
      it 'returns nil and logs error if payouts disabled' do
        allow(profile).to receive(:payouts_enabled?).and_return(false)
        expect(Rails.logger).to receive(:error).with(/Payouts disabled/)
        expect(service.call).to be_nil
      end

      it 'returns nil and logs error if bank details invalid' do
        allow(profile).to receive(:valid_bank_details?).and_return(false)
        expect(Rails.logger).to receive(:error).with(/Invalid Bank Details/)
        expect(service.call).to be_nil
      end
    end

    context 'when processing payouts' do
      let(:commissions) { double('Commissions') }
      let(:available_commissions) { double('AvailableCommissions', empty?: false, sum: 150.0, pluck: [1, 2]) }
      let(:payouts) { double('Payouts') }
      let(:payout) { double('Payout', id: 'pay_1') }

      before do
        allow(profile).to receive(:commissions).and_return(commissions)
        allow(commissions).to receive(:available).and_return(available_commissions)
        allow(profile).to receive(:payouts).and_return(payouts)
      end

      it 'returns nil if no available commissions' do
        allow(available_commissions).to receive(:empty?).and_return(true)
        expect(service.call).to be_nil
      end

      it 'returns nil if total payout is not positive' do
        allow(available_commissions).to receive(:sum).with(:amount).and_return(0.0)
        expect(service.call).to be_nil
      end

      it 'creates payout and updates commissions' do
        expect(payouts).to receive(:create!).with(
          amount: 150.0,
          currency: 'USD',
          status: :processing,
          commission_ids: [1, 2]
        ).and_return(payout)

        expect(available_commissions).to receive(:update_all).with(status: :paid)

        result = service.call
        expect(result).to eq(payout)
      end
    end
  end
end
