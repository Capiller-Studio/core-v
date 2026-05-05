FactoryBot.define do
  factory :address do
    address1 { FFaker::Address.street_address }
    city { FFaker::Address.city }
    zipcode { FFaker::AddressUS.zip_code }
    country
    state
  end
end
