FactoryBot.define do
  factory :ai_wallet, class: 'Ai::Wallet' do
    account

    initialize_with { Ai::Wallet.find_or_initialize_by(account: account) }

    balance { 0 }
  end
end
