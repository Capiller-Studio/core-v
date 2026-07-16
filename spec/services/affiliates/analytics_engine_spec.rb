require 'rails_helper'

RSpec.describe Affiliates::AnalyticsEngine do
  let(:profile) { double('Affiliate::Profile') }
  let(:service) { described_class.new(profile: profile) }

  describe '#call' do
    let(:click_scope) { double('ClickScope', count: 100) }
    let(:referral_scope) { double('ReferralScope', count: 5) }
    
    let(:commission_scope) { double('CommissionScope') }
    let(:non_voided_scope) { double('NonVoidedScope', sum: 500.0) }
    let(:pending_scope) { double('PendingScope', sum: 200.0) }
    let(:available_scope) { double('AvailableScope', sum: 150.0) }
    let(:paid_scope) { double('PaidScope', sum: 150.0) }

    before do
      stub_const('Affiliate::Click', double('ClickClass'))
      allow(Affiliate::Click).to receive(:where).with(profile: profile).and_return(click_scope)

      allow(profile).to receive(:referrals).and_return(referral_scope)
      
      allow(profile).to receive(:commissions).and_return(commission_scope)
      allow(commission_scope).to receive(:where).with(not: { status: :voided }).and_return(non_voided_scope)
      # ActiveRecord not() query mock workaround:
      allow(commission_scope).to receive_message_chain(:where, :not).with(status: :voided).and_return(non_voided_scope)

      allow(commission_scope).to receive(:pending).and_return(pending_scope)
      allow(commission_scope).to receive(:available).and_return(available_scope)
      allow(commission_scope).to receive(:paid).and_return(paid_scope)
    end

    it 'returns correctly calculated analytics metrics' do
      result = service.call

      expect(result[:total_clicks]).to eq(100)
      expect(result[:total_referrals]).to eq(5)
      expect(result[:conversion_rate]).to eq(5.0) # (5 / 100) * 100
      expect(result[:total_earnings]).to eq(500.0)
      expect(result[:pending_balance]).to eq(200.0)
      expect(result[:available_balance]).to eq(150.0)
      expect(result[:paid_balance]).to eq(150.0)
    end

    context 'when there are no clicks' do
      let(:click_scope) { double('ClickScope', count: 0) }

      it 'returns 0.0 for conversion rate' do
        result = service.call
        expect(result[:conversion_rate]).to eq(0.0)
      end
    end
  end
end
