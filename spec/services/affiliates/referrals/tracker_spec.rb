require 'rails_helper'

RSpec.describe Affiliates::Referrals::Tracker do
  let(:account) { double('Account', id: 'acc_1') }
  let(:profile) { double('Affiliate::Profile', user_id: 'user_1') }
  let(:service) { described_class.new(account: account, referral_code: 'REF123') }

  describe '#call' do
    before do
      stub_const('Affiliate::Profile', double('ProfileClass'))
      stub_const('Affiliate::Referral', double('ReferralClass'))
    end

    it 'returns nil if referral code is blank' do
      service = described_class.new(account: account, referral_code: '')
      expect(service.call).to be_nil
    end

    it 'returns nil if profile not found' do
      allow(Affiliate::Profile).to receive(:find_by).with(referral_code: 'REF123').and_return(nil)
      expect(service.call).to be_nil
    end

    context 'when profile is found' do
      let(:users_scope) { double('UsersScope') }

      before do
        allow(Affiliate::Profile).to receive(:find_by).with(referral_code: 'REF123').and_return(profile)
        allow(account).to receive(:users).and_return(users_scope)
      end

      it 'returns nil if self-referral (account contains profile user)' do
        allow(users_scope).to receive(:exists?).with(id: 'user_1').and_return(true)
        expect(service.call).to be_nil
      end

      it 'returns nil if referral already exists for account' do
        allow(users_scope).to receive(:exists?).with(id: 'user_1').and_return(false)
        allow(Affiliate::Referral).to receive(:exists?).with(account: account).and_return(true)
        
        expect(service.call).to be_nil
      end

      it 'creates a referral if valid' do
        allow(users_scope).to receive(:exists?).with(id: 'user_1').and_return(false)
        allow(Affiliate::Referral).to receive(:exists?).with(account: account).and_return(false)
        
        expect(Affiliate::Referral).to receive(:create!).with(
          profile: profile,
          account: account,
          status: :active
        )
        
        service.call
      end
    end
  end
end
