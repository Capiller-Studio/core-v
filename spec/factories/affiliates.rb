# frozen_string_literal: true

FactoryBot.define do
  factory :affiliate_profile, class: 'Affiliate::Profile' do
    user
    referral_code { SecureRandom.alphanumeric(8).downcase }
    payouts_enabled { true }
    commission_rate { 25.0 }
    currency { 'USD' }
  end

  factory :affiliate_payout_batch, class: 'Affiliate::PayoutBatch' do
    status { :pending }
  end

  factory :affiliate_referral, class: 'Affiliate::Referral' do
    association :profile, factory: :affiliate_profile
    account
    status { :active }
  end

  factory :affiliate_commission, class: 'Affiliate::Commission' do
    association :profile, factory: :affiliate_profile
    association :referral, factory: :affiliate_referral
    association :transaction_record, factory: :transaction
    amount { 25.0 }
    original_amount { 25.0 }
    currency { 'USD' }
    original_currency { 'USD' }
    status { :pending }
    commission_type { :normal }
  end

  factory :affiliate_payout, class: 'Affiliate::Payout' do
    association :profile, factory: :affiliate_profile
    amount { 100.0 }
    currency { 'USD' }
    status { :processing }
  end
end
