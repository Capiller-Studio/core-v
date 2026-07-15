FactoryBot.define do
  factory :access_token do
    association :owner, factory: :user
    token { SecureRandom.hex(20) }
    token_type { :api_key }
    valid_till { 1.year.from_now }
  end
end
