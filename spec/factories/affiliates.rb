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

  factory :affiliate_payout, class: 'Affiliate::Payout' do
    association :profile, factory: :affiliate_profile
    amount { 100.0 }
    currency { 'USD' }
    status { :processing }
  end
end
