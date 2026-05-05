FactoryBot.define do
  factory :state do
    abbr { FFaker::AddressUS.state_abbr }
    country
  end
end
