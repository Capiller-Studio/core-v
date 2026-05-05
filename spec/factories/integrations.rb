FactoryBot.define do
  factory :integration do
    account
    provider { :slack }
    active { true }
    settings { {} }
  end
end
