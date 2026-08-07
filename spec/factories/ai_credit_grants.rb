FactoryBot.define do
  factory :ai_credit_grant, class: 'Ai::CreditGrant' do
    association :wallet, factory: :ai_wallet
    
    amount { 100 }
    balance { 100 }
    grant_type { :purchased }
    expires_at { 1.year.from_now }
  end
end
