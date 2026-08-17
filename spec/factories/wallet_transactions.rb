# frozen_string_literal: true

FactoryBot.define do
  factory :wallet_transaction do
    account
    wallet { account.wallet || association(:wallet, account: account) }
    transaction_type { :topup }
    amount { 50.0 }
    balance_after { 50.0 }
    currency { 'USD' }
  end
end
