require 'rails_helper'

RSpec.describe Affiliates::Commissions::Calculator do
  let(:account) { double('Account', id: 'acc_123') }
  let(:transaction) { double('Transaction', id: 'txn_123', account_id: 'acc_123', charge?: true, completed?: true, amount: 100.0, currency: 'USD') }
  let(:service) { described_class.new(transaction: transaction) }
  let(:profile) { double('Affiliate::Profile', commission_rate: 20.0, currency: 'EUR', max_earnings_per_account: nil, holding_days: 14) }
  let(:referral) { double('Affiliate::Referral', remaining_tenure_months: 12, profile: profile, total_commission: 0.0) }
  
  before do
    stub_const('Affiliate::Referral', double('ReferralClass'))
    allow(Affiliate::Referral).to receive_message_chain(:active, :find_by).with(account_id: 'acc_123').and_return(referral)
    
    allow(Affiliates::CurrencyConverter).to receive(:call).with(from_currency: 'USD', to_currency: 'EUR').and_return(0.85)
    stub_const('Affiliate::Commission', double('CommissionClass'))
  end

  describe '#call' do
    it 'calculates and creates a commission record' do
      expect(Affiliate::Commission).to receive(:create!).with(
        profile: profile,
        referral: referral,
        transaction_record: transaction,
        original_amount: 20.0,
        original_currency: 'USD',
        exchange_rate: 0.85,
        amount: 17.0,
        currency: 'EUR',
        status: :pending
      )
      
      service.call
    end

    it 'expires referral if tenure is 0' do
      allow(referral).to receive(:remaining_tenure_months).and_return(0)
      expect(referral).to receive(:expired!)
      
      expect(Affiliate::Commission).not_to receive(:create!)
      
      service.call
    end

    it 'caps earnings if max_earnings_per_account is reached' do
      allow(profile).to receive(:max_earnings_per_account).and_return(50.0)
      allow(referral).to receive(:total_commission).and_return(40.0)
      
      expect(referral).to receive(:expired!)
      
      expect(Affiliate::Commission).to receive(:create!).with(
        hash_including(amount: 10.0) # Headroom is 10.0, which is less than 17.0
      )
      
      service.call
    end
    
    it 'does not create commission if headroom is 0' do
      allow(profile).to receive(:max_earnings_per_account).and_return(50.0)
      allow(referral).to receive(:total_commission).and_return(50.0)
      
      expect(referral).to receive(:expired!)
      expect(Affiliate::Commission).not_to receive(:create!)
      
      service.call
    end

    it 'sets status to available if holding_days is 0' do
      allow(profile).to receive(:holding_days).and_return(0)
      
      expect(Affiliate::Commission).to receive(:create!).with(
        hash_including(status: :available)
      )
      
      service.call
    end
  end
end
