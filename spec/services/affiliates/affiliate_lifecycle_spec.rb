# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Affiliate Modules Comprehensive Lifecycle Suite', type: :service do
  let(:partner_user) { create(:user, email: 'top.partner@affiliate.example.com') }
  let(:profile) do
    create(:affiliate_profile,
      user: partner_user,
      referral_code: 'AFF-MASTER-2026',
      commission_rate: 20.0,
      tenure_months: 12,
      max_earnings_per_account: 500.00,
      holding_days: 14,
      currency: 'USD',
      payouts_enabled: true
    )
  end

  let(:client_user) { create(:user, email: 'client@startup.example.com') }
  let(:client_account) { create(:account, email: 'billing@startup.example.com') }
  let!(:client_account_user) { create(:account_user, account: client_account, user: client_user, owner: true) }

  describe 'Affiliates::Referrals::Tracker Edge Cases' do
    it 'ignores blank or nil referral code' do
      expect {
        Affiliates::Referrals::Tracker.call(account: client_account, referral_code: '')
        Affiliates::Referrals::Tracker.call(account: client_account, referral_code: nil)
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'ignores non-existent referral code' do
      expect {
        Affiliates::Referrals::Tracker.call(account: client_account, referral_code: 'NON_EXISTENT_CODE')
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'blocks self-referrals when account user matches affiliate profile user_id' do
      self_account = create(:account)
      create(:account_user, account: self_account, user: partner_user, owner: true)

      expect {
        Affiliates::Referrals::Tracker.call(account: self_account, referral_code: profile.referral_code)
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'blocks self-referrals when account email matches partner user email case-insensitively' do
      self_account = create(:account, email: 'TOP.PARTNER@affiliate.example.com')

      expect {
        Affiliates::Referrals::Tracker.call(account: self_account, referral_code: profile.referral_code)
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'blocks self-referrals when account user matches affiliate profile user_id' do
      self_account = create(:account)
      create(:account_user, account: self_account, user: partner_user, owner: true)

      expect {
        Affiliates::Referrals::Tracker.call(account: self_account, referral_code: profile.referral_code)
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'prevents duplicate referral mappings for the same account' do
      create(:affiliate_referral, profile: profile, account: client_account, status: :active)

      expect {
        Affiliates::Referrals::Tracker.call(account: client_account, referral_code: profile.referral_code)
      }.not_to change(Affiliate::Referral, :count)
    end

    it 'successfully links new account to affiliate referral record' do
      expect {
        Affiliates::Referrals::Tracker.call(account: client_account, referral_code: profile.referral_code)
      }.to change(Affiliate::Referral, :count).by(1)

      referral = Affiliate::Referral.last
      expect(referral.profile).to eq(profile)
      expect(referral.account).to eq(client_account)
      expect(referral).to be_active
    end
  end

  describe 'Affiliates::Commissions::Calculator Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }

    it 'ignores non-charge or non-completed transactions' do
      tx_pending = create(:transaction, account: client_account, transaction_type: :charge, status: :pending, amount: 100.0)
      tx_refund = create(:transaction, account: client_account, transaction_type: :refund, status: :completed, amount: 100.0)

      expect {
        Affiliates::Commissions::Calculator.call(transaction: tx_pending)
        Affiliates::Commissions::Calculator.call(transaction: tx_refund)
      }.not_to change(Affiliate::Commission, :count)
    end

    it 'expires referral and skips commission if tenure limit has lapsed (remaining_tenure_months <= 0)' do
      referral.update!(created_at: 14.months.ago)

      tx = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 100.0)

      expect {
        Affiliates::Commissions::Calculator.call(transaction: tx)
      }.not_to change(Affiliate::Commission, :count)

      expect(referral.reload).to be_expired
    end

    it 'calculates standard commission and sets status to pending when holding_days > 0' do
      tx = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 200.0, currency: 'USD')

      comm = Affiliate::Commission.find_by(transaction_record_id: tx.id)
      expect(comm).to be_present
      expect(comm.amount).to eq(40.00) # 20% of 200.00
      expect(comm.currency).to eq('USD')
      expect(comm.status).to eq('pending')
    end

    it 'sets commission directly to available if holding_days is 0' do
      profile.update!(holding_days: 0)

      tx = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 100.0, currency: 'USD')

      comm = Affiliate::Commission.find_by(transaction_record_id: tx.id)
      expect(comm).to be_present
      expect(comm.status).to eq('available')
    end

    it 'applies currency conversion when transaction currency differs from affiliate currency' do
      allow(Affiliates::CurrencyConverter).to receive(:call).with(from_currency: 'EUR', to_currency: 'USD').and_return(1.10)

      tx = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 100.0, currency: 'EUR')

      comm = Affiliate::Commission.find_by(transaction_record_id: tx.id)
      expect(comm).to be_present
      expect(comm.original_amount).to eq(20.00) # 20% of 100 EUR
      expect(comm.original_currency).to eq('EUR')
      expect(comm.amount).to eq(22.00) # 20.00 * 1.10
      expect(comm.currency).to eq('USD')
    end

    it 'caps commission and expires referral when max_earnings_per_account limit is reached' do
      profile.update!(max_earnings_per_account: 50.00)

      # First transaction creates commission of 40.00
      tx1 = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 200.0, currency: 'USD')
      comm1 = Affiliate::Commission.find_by(transaction_record_id: tx1.id)
      expect(comm1.amount).to eq(40.00)

      # Second transaction would earn 40.00, but headroom is only 10.00
      tx2 = create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 200.0, currency: 'USD')
      comm2 = Affiliate::Commission.find_by(transaction_record_id: tx2.id)

      expect(comm2.amount).to eq(10.00) # capped to remaining headroom
      expect(referral.reload).to be_expired
    end
  end

  describe 'Affiliates::Commissions::Refunder Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }
    let(:charge_tx) { create(:transaction, account: client_account, transaction_type: :charge, status: :completed, amount: 100.0, currency: 'USD') }

    it 'voids unpaid (pending/available) commission on full refund' do
      comm = Affiliate::Commission.find_by(transaction_record_id: charge_tx.id)
      expect(comm).to be_present
      expect(comm).to be_pending

      Affiliates::Commissions::Refunder.call(transaction: charge_tx, refund_amount: 100.0)
      expect(comm.reload).to be_voided
    end

    it 'issues negative commission ledger entry on partial refund of unpaid commission' do
      comm = Affiliate::Commission.find_by(transaction_record_id: charge_tx.id)
      comm.update!(status: :available)

      expect {
        Affiliates::Commissions::Refunder.call(transaction: charge_tx, refund_amount: 50.0)
      }.to change(Affiliate::Commission, :count).by(1)

      clawback = Affiliate::Commission.where(commission_type: :refund).last
      expect(clawback.commission_type).to eq('refund')
      expect(clawback.amount).to eq(-10.00) # 50% of 20.0
      expect(clawback.original_commission_id).to eq(comm.id)
      expect(comm.reload).to be_available
    end

    it 'issues severe negative commission ledger entry when refunded transaction was already paid out' do
      comm = Affiliate::Commission.find_by(transaction_record_id: charge_tx.id)
      comm.update!(status: :paid)

      expect {
        Affiliates::Commissions::Refunder.call(transaction: charge_tx, refund_amount: 100.0)
      }.to change(Affiliate::Commission, :count).by(1)

      clawback = Affiliate::Commission.where(commission_type: :refund).last
      expect(clawback.commission_type).to eq('refund')
      expect(clawback.amount).to eq(-20.00)
      expect(clawback.status).to eq('available') # immediately offsets next payout
      expect(comm.reload).to be_paid
    end
  end

  describe 'Affiliates::Commissions::HoldingManager Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }

    it 'transitions pending commissions to available after holding period has matured' do
      matured_comm = create(:affiliate_commission,
        profile: profile,
        referral: referral,
        amount: 50.0,
        status: :pending,
        created_at: 15.days.ago
      )

      fresh_comm = create(:affiliate_commission,
        profile: profile,
        referral: referral,
        amount: 25.0,
        status: :pending,
        created_at: 2.days.ago
      )

      Affiliates::Commissions::HoldingManager.call

      expect(matured_comm.reload).to be_available
      expect(fresh_comm.reload).to be_pending
    end
  end

  describe 'Affiliates::Payouts::Generator Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }

    before do
      allow(profile).to receive(:valid_bank_details?).and_return(true)
    end

    it 'returns nil safely if payouts are disabled on profile' do
      profile.update!(payouts_enabled: false)
      result = Affiliates::Payouts::Generator.call(profile: profile)
      expect(result).to be_nil
    end

    it 'aggregates available commissions, marks them paid, and creates payout record' do
      c1 = create(:affiliate_commission, profile: profile, referral: referral, amount: 100.0, status: :available)
      c2 = create(:affiliate_commission, profile: profile, referral: referral, amount: 50.0, status: :available)
      create(:affiliate_commission, profile: profile, referral: referral, amount: 25.0, status: :pending)

      payout = Affiliates::Payouts::Generator.call(profile: profile)

      expect(payout).to be_present
      expect(payout.amount).to eq(150.0)
      expect(payout.status).to eq('processing')
      expect(payout.commission_ids).to contain_exactly(c1.id, c2.id)

      expect(c1.reload).to be_paid
      expect(c2.reload).to be_paid
    end

    it 'halts payout creation safely if negative adjustments outpace earnings (net <= 0)' do
      create(:affiliate_commission, profile: profile, referral: referral, amount: 50.0, status: :available)
      create(:affiliate_commission, profile: profile, referral: referral, amount: -75.0, status: :available)

      payout = Affiliates::Payouts::Generator.call(profile: profile)
      expect(payout).to be_nil
      expect(Affiliate::Payout.count).to eq(0)
    end
  end

  describe 'Affiliates::BankDetailsValidator Edge Cases' do
    let(:country) { create(:country, iso: 'US', iso_name: 'United States') }
    let(:address) { create(:address, country: country) }
    let(:user_with_address) { create(:user, address: address) }
    let(:bank_profile) { create(:affiliate_profile, user: user_with_address, payment_method_type: :bank) }

    it 'fails validation when payment_method_type is not bank' do
      allow(bank_profile).to receive(:bank?).and_return(false)
      result = Affiliates::BankDetailsValidator.call(bank_profile)
      expect(result.success?).to be false
      expect(result.error).to eq('Not a bank payment method')
    end

    it 'fails validation when user address or country is missing' do
      user_no_addr = build(:user, address: nil)
      profile_no_address = build(:affiliate_profile, user: user_no_addr, payment_method_type: :bank)
      result = Affiliates::BankDetailsValidator.call(profile_no_address)
      expect(result.success?).to be false
      expect(result.error).to eq('Missing User Address or Country Code')
    end

    it 'validates EUR bank details requiring IBAN and account holder name' do
      bank_profile.assign_attributes(currency: 'EUR', payment_details: { 'account_holder_name' => 'Euro Partner' })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be false

      bank_profile.assign_attributes(payment_details: { 'iban' => 'DE89370400440532013000', 'account_holder_name' => 'Euro Partner' })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be true
    end

    it 'validates USD bank details requiring routing, account number, account type, and holder name' do
      bank_profile.assign_attributes(currency: 'USD', payment_details: { 'account_holder_name' => 'US Partner' })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be false

      bank_profile.assign_attributes(payment_details: {
        'routing_number' => '121000358',
        'account_number' => '9876543210',
        'account_type' => 'CHECKING',
        'account_holder_name' => 'US Partner'
      })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be true
    end

    it 'validates GBP bank details requiring sort code, account number, and holder name' do
      bank_profile.assign_attributes(currency: 'GBP', payment_details: { 'account_holder_name' => 'UK Partner' })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be false

      bank_profile.assign_attributes(payment_details: {
        'sort_code' => '40-47-84',
        'account_number' => '70872490',
        'account_holder_name' => 'UK Partner'
      })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be true
    end

    it 'validates KRW bank details requiring bank code, account number, and holder name' do
      bank_profile.assign_attributes(currency: 'KRW', payment_details: { 'account_holder_name' => 'KR Partner' })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be false

      bank_profile.assign_attributes(payment_details: {
        'bank_code' => '004',
        'account_number' => '1234567890',
        'account_holder_name' => 'KR Partner'
      })
      expect(Affiliates::BankDetailsValidator.call(bank_profile).success?).to be true
    end

    it 'fails validation for unsupported currencies' do
      bank_profile.assign_attributes(currency: 'JPY', payment_details: { 'account_holder_name' => 'JP Partner' })
      result = Affiliates::BankDetailsValidator.call(bank_profile)
      expect(result.success?).to be false
      expect(result.error).to include('Unsupported Currency: JPY')
    end
  end

  describe 'Affiliates::CurrencyConverter Edge Cases' do
    it 'returns 1.0 when from and to currencies match' do
      expect(Affiliates::CurrencyConverter.call(from_currency: 'USD', to_currency: 'USD')).to eq(1.0)
      expect(Affiliates::CurrencyConverter.call(from_currency: 'eur', to_currency: 'EUR')).to eq(1.0)
    end

    it 'applies 2.5% platform spread fee protecting platform margins' do
      create(:exchange_rate, from_currency: 'EUR', to_currency: 'USD', rate: 1.10)
      # 1.10 * (1 - 0.025) = 1.10 * 0.975 = 1.0725
      rate = Affiliates::CurrencyConverter.call(from_currency: 'EUR', to_currency: 'USD')
      expect(rate).to eq(1.0725)
    end

    it 'falls back safely to 1.0 if live exchange rate record is not found' do
      rate = Affiliates::CurrencyConverter.call(from_currency: 'CHF', to_currency: 'USD')
      expect(rate).to eq(1.0)
    end
  end

  describe 'Affiliates::AnalyticsEngine Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }

    before do
      click_class = Class.new do
        def self.where(*)
          self
        end
        def self.count
          0
        end
      end
      stub_const('Affiliate::Click', click_class)
    end

    it 'handles zero clicks gracefully and reports 0.0% conversion rate without division by zero' do
      data = Affiliates::AnalyticsEngine.call(profile: profile)
      expect(data[:total_clicks]).to eq(0)
      expect(data[:conversion_rate]).to eq(0.0)
      expect(data[:total_referrals]).to eq(1)
    end

    it 'accurately calculates conversion rate and separates available vs pending vs voided balances' do
      allow(Affiliate::Click).to receive(:count).and_return(4)
      create(:affiliate_commission, profile: profile, referral: referral, amount: 100.0, status: :available)
      create(:affiliate_commission, profile: profile, referral: referral, amount: 50.0, status: :pending)
      create(:affiliate_commission, profile: profile, referral: referral, amount: 200.0, status: :paid)
      create(:affiliate_commission, profile: profile, referral: referral, amount: 300.0, status: :voided)

      data = Affiliates::AnalyticsEngine.call(profile: profile)
      expect(data[:total_clicks]).to eq(4)
      # 1 referral / 4 clicks = 25.0%
      expect(data[:conversion_rate]).to eq(25.0)
      expect(data[:available_balance]).to eq(100.0)
      expect(data[:pending_balance]).to eq(50.0)
      expect(data[:paid_balance]).to eq(200.0)
      # Voided commissions are excluded from total earnings: 100 + 50 + 200 = 350.0
      expect(data[:total_earnings]).to eq(350.0)
    end
  end

  describe 'Affiliates::Payouts::Processor & DryRun Edge Cases' do
    let!(:referral) { create(:affiliate_referral, profile: profile, account: client_account, status: :active) }

    describe 'Affiliates::Payouts::DryRun' do
      it 'calculates preview of eligible payouts without persisting records or altering commission statuses' do
        c = create(:affiliate_commission, profile: profile, referral: referral, amount: 120.50, status: :available)
        allow(profile).to receive(:valid_bank_details?).and_return(true)

        preview = Affiliates::Payouts::DryRun.call(profile_ids: [profile.id])
        expect(preview.size).to eq(1)
        expect(preview.first[:profile_id]).to eq(profile.id)
        expect(preview.first[:amount]).to eq(120.50)
        expect(preview.first[:commission_count]).to eq(1)

        # Confirm zero database modifications
        expect(c.reload).to be_available
        expect(Affiliate::Payout.count).to eq(0)
      end
    end

    describe 'Affiliates::Payouts::Processor' do
      it 'is idempotent and ignores already paid payouts' do
        payout = create(:affiliate_payout, profile: profile, status: :paid, provider: :manual)
        expect_any_instance_of(Affiliates::Payouts::Processor).not_to receive(:process_payout!)
        Affiliates::Payouts::Processor.call(payout: payout)
      end

      it 'restores commissions to available status on payout processing failure' do
        c1 = create(:affiliate_commission, profile: profile, referral: referral, amount: 75.0, status: :paid)
        payout = create(:affiliate_payout, profile: profile, status: :processing, provider: :manual, commission_ids: [c1.id])

        # Simulate exception during payout execution
        allow_any_instance_of(Affiliates::Payouts::Processor).to receive(:process_payout!).and_raise(StandardError, 'Bank Gateway Timeout')

        Affiliates::Payouts::Processor.call(payout: payout)

        expect(payout.reload).to be_failed
        # Commission is restored back to available so affiliate does not lose balance
        expect(c1.reload).to be_available
      end
    end
  end
end
