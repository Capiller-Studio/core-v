require 'rails_helper'

RSpec.describe Affiliate::StatsCalculator do
  let(:profile) { double('AffiliateProfile') }
  let(:commissions) { double('Commissions') }
  let(:payouts) { double('Payouts') }
  let(:referrals) { double('Referrals') }

  let(:service) { described_class.new(profile) }

  before do
    allow(profile).to receive(:commissions).and_return(commissions)
    allow(profile).to receive(:payouts).and_return(payouts)
    allow(profile).to receive(:referrals).and_return(referrals)
  end

  describe '#calculate' do
    it 'returns calculated stats' do
      available_paid_commissions = double('AvailablePaidCommissions', sum: 100.0)
      pending_commissions = double('PendingCommissions', sum: 50.0)
      paid_payouts = double('PaidPayouts', sum: 80.0)

      allow(commissions).to receive(:where).with(status: [:available, :paid]).and_return(available_paid_commissions)
      allow(commissions).to receive(:pending).and_return(pending_commissions)
      
      allow(payouts).to receive(:paid).and_return(paid_payouts)
      allow(referrals).to receive(:count).and_return(10)

      result = service.calculate

      expect(result).to eq({
        total_commission: 100.0,
        pending_commission: 50.0,
        total_paid: 80.0,
        referral_count: 10
      })
    end
  end
end
