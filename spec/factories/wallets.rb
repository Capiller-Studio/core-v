FactoryBot.define do
  factory :wallet do
    account

    initialize_with { Wallet.find_or_initialize_by(account: account) }

    balance { 0 }
    currency { account.currency || 'USD' }
  end
end
