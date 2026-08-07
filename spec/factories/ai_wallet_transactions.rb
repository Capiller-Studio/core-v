FactoryBot.define do
  factory :ai_wallet_transaction, class: 'Ai::WalletTransaction' do
    account
    association :wallet, factory: :ai_wallet
    
    amount { 10 }
    balance_after { 90 }
    transaction_type { :deduction }
  end
end
